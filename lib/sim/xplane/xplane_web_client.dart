import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Transport seam over X-Plane 12's local Web API (v12.1.1+):
/// REST for capabilities/dataref-name resolution, WebSocket for streaming
/// dataref values at ~10 Hz. An abstract [XPlaneTransport] keeps the
/// connector testable against fakes; [XPlaneWebClient] is the real one.
///
/// Dataref ids are session-scoped (they change across X-Plane restarts),
/// so names are resolved per connection and cached on the transport.
abstract class XPlaneTransport {
  /// Probes `/api/capabilities`; returns the X-Plane version string
  /// (e.g. "12.4.0") or throws when the server is unreachable / the API
  /// is disabled (HTTP 403).
  Future<String> probe();

  /// Resolves dataref NAMES to session ids; unknown names are omitted
  /// from the result.
  Future<Map<String, int>> resolve(Set<String> names);

  /// Subscribes to value updates for the given ids (idempotent).
  Future<void> subscribe(Iterable<int> ids);

  /// Broadcast stream of update batches: dataref id → current value
  /// (only changed values are pushed by the sim).
  Stream<Map<int, dynamic>> get updates;

  /// Closes the transport (socket + pending state).
  Future<void> dispose();
}

/// Real transport: REST via dio, streaming via a WebSocket to
/// `ws://127.0.0.1:{port}/api/v3`.
class XPlaneWebClient implements XPlaneTransport {
  XPlaneWebClient({required this.port});

  final int port;
  final Dio _dio = Dio()
    ..options.connectTimeout = const Duration(seconds: 3)
    ..options.receiveTimeout = const Duration(seconds: 5);

  WebSocketChannel? _socket;
  WebSocketSink? _sink;
  int _reqId = 0;
  final _pending = <int, Completer<void>>{};
  final _updates = StreamController<Map<int, dynamic>>.broadcast();

  @override
  Stream<Map<int, dynamic>> get updates => _updates.stream;

  bool get isOpen => _socket != null;

  @override
 Future<String> probe() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        'http://127.0.0.1:$port/api/capabilities',
      );
      final data = res.data;
      final version = data?['x-plane']?['version'];
      if (version is String && version.isNotEmpty) return version;
      throw Exception('capabilities response missing x-plane version');
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception(
          'X-Plane refuses incoming API traffic '
          '(Settings → Network → allow incoming traffic)',
        );
      }
      throw Exception('X-Plane Web API unreachable on port $port');
    }
  }

  /// Opens the WebSocket and keeps it draining. Idempotent.
  Future<void> _ensureSocket() async {
    if (_socket != null) return;
    final channel = WebSocketChannel.connect(
      Uri.parse('ws://127.0.0.1:$port/api/v3'),
    );
    await channel.ready.timeout(const Duration(seconds: 4));
    _socket = channel;
    _sink = channel.sink;
    channel.stream
        .cast<String>()
        .listen(_onMessage, onDone: _onClosed, onError: (_) => _onClosed());
  }

  void _onMessage(String raw) {
    final Map<String, dynamic> message;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      message = decoded;
    } on FormatException {
      return;
    }
    switch (message['type']) {
      case 'result':
        final id = message['req_id'];
        final completer = _pending.remove(id);
        if (completer == null) return;
        if (message['success'] == true) {
          completer.complete();
        } else {
          completer.completeError(
            Exception('${message['error_code']}: ${message['error_message']}'),
          );
        }
      case 'dataref_update_values':
        final data = message['data'];
        if (data is! Map) return;
        final batch = <int, dynamic>{};
        for (final entry in data.entries) {
          final id = int.tryParse('${entry.key}'.trim());
          if (id != null) batch[id] = entry.value;
        }
        if (batch.isNotEmpty) _updates.add(batch);
    }
  }

  void _onClosed() {
    final pending = List.of(_pending.values);
    _pending.clear();
    for (final c in pending) {
      c.completeError(Exception('websocket closed'));
    }
    _socket = null;
    _sink = null;
  }

  Future<void> _send(
    String type,
    Map<String, dynamic> params,
  ) async {
    await _ensureSocket();
    final id = ++_reqId;
    final completer = Completer<void>();
    _pending[id] = completer;
    _sink!.add(jsonEncode({'req_id': id, 'type': type, 'params': params}));
    return completer.future.timeout(const Duration(seconds: 4));
  }

  @override
  Future<Map<String, int>> resolve(Set<String> names) async {
    final out = <String, int>{};
    // One filter query per name (the API ors same-field filters, but a
    // single batched query then needs mapping back — per-name queries are
    // simpler and the set is small and asked once per connection).
    for (final name in names) {
      try {
        final res = await _dio.get<Map<String, dynamic>>(
          'http://127.0.0.1:$port/api/v3/datarefs',
          queryParameters: {'filter[name]': name, 'fields': 'id,name'},
        );
        final list = res.data?['data'];
        if (list is! List || list.isEmpty) continue;
        for (final row in list) {
          if (row is Map<String, dynamic> && row['name'] == name) {
            final id = row['id'];
            if (id is int) out[name] = id;
            break;
          }
        }
      } on DioException {
        // Name unknown to this aircraft/session — leave it unresolved.
      }
    }
    return out;
  }

  @override
  Future<void> subscribe(Iterable<int> ids) async {
    final list = [for (final id in ids) {'id': id}];
    if (list.isEmpty) return;
    await _send('dataref_subscribe_values', {'datarefs': list});
  }

  @override
  Future<void> dispose() async {
    _onClosed();
    await _updates.close();
    try {
      await _sink?.close();
    } on Exception {
      // Already gone.
    }
  }
}

/// Fake transport for tests — scripted probe/resolve results plus a
/// sink to push update batches from the test body.
@visibleForTesting
class FakeXPlaneTransport implements XPlaneTransport {
  FakeXPlaneTransport({this.version = '12.4.0', this.known = const {}});

  String version;
  Map<String, int> known;
  final List<int> subscribed = [];
  final _updates = StreamController<Map<int, dynamic>>.broadcast();

  void emit(Map<int, dynamic> batch) => _updates.add(batch);

  @override
  Future<String> probe() async => version;

  @override
  Future<Map<String, int>> resolve(Set<String> names) async => {
        for (final e in known.entries)
          if (names.contains(e.key)) e.key: e.value,
      };

  @override
  Future<void> subscribe(Iterable<int> ids) async {
    subscribed.addAll(ids);
  }

  @override
  Stream<Map<int, dynamic>> get updates => _updates.stream;

  @override
  Future<void> dispose() async {
    await _updates.close();
  }
}

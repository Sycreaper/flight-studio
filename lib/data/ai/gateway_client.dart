import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File, FileMode, Platform;

import 'package:dio/dio.dart';

/// Gateway/letta API call failed — [message] carries the server's raw error
/// text (already English; shown to the user verbatim for diagnostics).
class GatewayApiException implements Exception {
  GatewayApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Flutter-side client for the FlightStudio Agent Gateway
/// (`agent_gateway/` — HTTP + SSE bridge to the Letta Agent SDK).
///
/// The app only speaks this small HTTP + SSE API; Letta protocol details
/// (streaming, permissions, tools, memory) live entirely in the gateway.
class GatewayClient {
  GatewayClient._();

  static final GatewayClient instance = GatewayClient._();

  static const baseUrl = 'http://127.0.0.1:8787';

  final Dio _dio = Dio()
    ..options.connectTimeout = const Duration(seconds: 5)
    ..options.receiveTimeout = const Duration(minutes: 5);

  /// Extracts the gateway's `{error: …}` (or raw) body from a dio failure.
  String _serverMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] != null) {
        return '${data['error']}';
      }
      if (data != null) return '$data';
      return error.message ?? error.type.name;
    }
    return error.toString();
  }

  /// Gateway + Letta health. Returns null when unreachable.
  Future<Map<String, dynamic>?> status() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('$baseUrl/agent/status');
      return res.data;
    } on Exception catch (_) {
      return null;
    }
  }

  /// Starts one user turn. Returns `null` when accepted, otherwise the
  /// gateway's rejection reason (e.g. "a turn is already running").
  Future<String?> sendMessage(String text) async {
    Map<String, dynamic>? body;
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/agent/message',
        data: {'text': text},
      );
      if (res.statusCode == 200) return null;
      body = res.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) body = Map<String, dynamic>.from(data);
    }
    return body?['reason'] as String? ?? body?['error'] as String? ??
        'unknown error';
  }

  /// Subscribes to the SSE event stream for [sessionId]. Returns a stream of
  /// decoded events; cancelling the subscription disconnects.
  Stream<Map<String, dynamic>> events({String sessionId = 'default'}) {
    final cancelToken = CancelToken();
    final controller = StreamController<Map<String, dynamic>>(
      onCancel: () => cancelToken.cancel(),
    );

    connect() async {
      try {
        final res = await _dio.get<ResponseBody>(
          '$baseUrl/agent/events/$sessionId',
          options: Options(
            responseType: ResponseType.stream,
            headers: {'Accept': 'text/event-stream'},
          ),
          cancelToken: cancelToken,
        );
        var eventName = '';
        res.data!.stream
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
              (line) {
                if (line.startsWith('event: ')) {
                  eventName = line.substring(7);
                } else if (line.startsWith('data: ')) {
                  try {
                    final data =
                        jsonDecode(line.substring(6)) as Map<String, dynamic>;
                    controller.add({'event': eventName, ...data});
                  } on FormatException catch (_) {}
                }
                // Heartbeat comments (`: ping`) and blank lines are ignored.
              },
              onDone: () => controller.close(),
              onError: (Object e) => controller.addError(e),
            );
      } on Exception catch (e) {
        controller.addError(e);
        controller.close();
      }
    }

    connect();
    return controller.stream;
  }

  /// Aborts the running turn.
  Future<void> stop({String sessionId = 'default'}) async {
    try {
      await _dio.post('$baseUrl/agent/stop/$sessionId');
    } on Exception catch (_) {
      // Best-effort.
    }
  }

  /// Pushes one OpenAI-compatible credential from the key vault to the
  /// Letta runtime (official `connect_provider` protocol under the hood) and
  /// switches the agent's model. Throws [GatewayApiException] carrying the
  /// gateway/Letta error text.
  ///
  /// NOTE: the [baseUrl] parameter is the LLM endpoint carried in the
  /// payload — the gateway itself is always [GatewayClient.baseUrl]
  /// (the parameter must never shadow it in request URLs).
  Future<void> setProvider({
    required String apiKey,
    required String baseUrl,
    required String model,
    String? reasoningEffort,
  }) async {
    try {
      final res = await _dio.post(
        '${GatewayClient.baseUrl}/agent/provider',
        data: {
          'apiKey': apiKey,
          'baseUrl': baseUrl,
          'model': model,
          'reasoningEffort': ?reasoningEffort,
        },
      );
      _diag('setProvider HTTP ${res.statusCode}');
    } on DioException catch (e) {
      _diag('setProvider dio error: type=${e.type} '
          'status=${e.response?.statusCode} '
          'url=${e.requestOptions.uri} '
          'body=${e.response?.data}');
      throw GatewayApiException(_serverMessage(e));
    } on Exception catch (e) {
      _diag('setProvider error: $e');
      throw GatewayApiException(e.toString());
    }
  }

  /// Appends a line to %TEMP%\flightstudio-chat.log (diagnostics only).
  void _diag(String line) {
    try {
      final f = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
            'flightstudio-chat.log',
      );
      f.writeAsStringSync(
        '${DateTime.now().toIso8601String()} [gw-client] $line\n',
        mode: FileMode.append,
      );
    } on Exception {
      // Best-effort.
    }
  }

  /// Lists available Letta agents (accounts).
  Future<List<Map<String, dynamic>>> listAgents() async {
    try {
      final res = await _dio.get<List<dynamic>>('$baseUrl/agent/list');
      if (res.data == null) return const [];
      return res.data!
          .whereType<Map<String, dynamic>>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    } on Exception catch (_) {
      return const [];
    }
  }

  /// Creates a new Letta agent (one per local account).
  Future<String?> createAgent(String name, {String? persona}) async {
    try {
      final body = <String, dynamic>{'name': name};
      if (persona != null) body['persona'] = persona;
      final res = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/agent/create',
        data: body,
      );
      return res.data?['id'] as String?;
    } on Exception catch (_) {
      return null;
    }
  }

  /// Deletes a Letta agent and its memories.
  Future<void> deleteAgent(String agentId) async {
    try {
      await _dio.post('$baseUrl/agent/delete', data: {'agentId': agentId});
    } on Exception catch (_) {
      // Best-effort.
    }
  }
}

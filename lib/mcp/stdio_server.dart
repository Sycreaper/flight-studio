import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'core_tools.dart';

/// Minimal MCP (Model Context Protocol) stdio server: newline-delimited
/// JSON-RPC 2.0 over stdin/stdout, implementing the tool-server subset —
/// initialize / notifications/initialized / tools/list / tools/call / ping.
/// Written by hand (≈150 lines) so the FlightStudio Core server stays a
/// plain `dart run` program with zero extra dependencies.
class McpStdioServer {
  McpStdioServer({
    required this.name,
    required this.version,
    required this.toolServer,
    Stream<String>? input,
    StringSink? output,
  }) : _injectedInput = input,
       _output = output ?? stdout;

  final String name;
  final String version;
  final CoreToolServer toolServer;

  final Stream<String>? _injectedInput;
  final StringSink _output;

  static const _defaultProtocolVersion = '2025-06-18';
  static const _supportedVersions = {'2024-11-05', '2025-03-26', '2025-06-18'};

  /// Runs until the input stream closes. Each line is one JSON-RPC message;
  /// responses are written as single lines to the output sink.
  Future<void> run() async {
    final Stream<String> input = _injectedInput ??
        stdin
            .transform(utf8.decoder)
            .transform(const LineSplitter());
    await for (final line in input) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final Object? message;
      try {
        message = jsonDecode(trimmed);
      } on FormatException {
        _log('ignoring non-JSON line');
        continue;
      }
      if (message is! Map<String, dynamic>) continue;
      await _handle(message);
    }
  }

  Future<void> _handle(Map<String, dynamic> message) async {
    final method = message['method'] as String?;
    final id = message['id'];

    // Notifications (no id) never get a response.
    if (id == null) return;

    switch (method) {
      case 'initialize':
        final requested = '${message['params']?['protocolVersion'] ?? ''}';
        _respond(id, {
          'protocolVersion': _supportedVersions.contains(requested)
              ? requested
              : _defaultProtocolVersion,
          'capabilities': {
            'tools': {'listChanged': false},
          },
          'serverInfo': {'name': name, 'version': version},
        });
      case 'ping':
        _respond(id, {});
      case 'tools/list':
        _respond(id, {
          'tools': [
            for (final t in toolServer.tools)
              {
                'name': t.name,
                'description': t.description,
                'inputSchema': t.schema,
              },
          ],
        });
      case 'tools/call':
        await _handleToolCall(id, message['params'] as Map<String, dynamic>?);
      default:
        _respondError(id, -32601, 'Method not found: ${method ?? '(none)'}');
    }
  }

  Future<void> _handleToolCall(
    Object id,
    Map<String, dynamic>? params,
  ) async {
    final rawName = params?['name'] as String? ?? '';
    final tool = toolServer.toolByName(rawName);
    if (tool == null) {
      _respondError(id, -32602, 'Unknown tool: $rawName');
      return;
    }
    final rawArgs = params?['arguments'];
    final args = rawArgs is Map<String, dynamic>
        ? rawArgs
        : const <String, dynamic>{};
    try {
      final result = await toolServer.invoke(tool, args);
      _respond(id, {
        'content': [
          {'type': 'text', 'text': result},
        ],
        'isError': false,
      });
    } on Exception catch (e) {
      // Tool failures are RESULTS (isError), not protocol errors.
      _respond(id, {
        'content': [
          {'type': 'text', 'text': 'error: $e'},
        ],
        'isError': true,
      });
    }
  }

  void _respond(Object id, Map<String, dynamic> result) =>
      _write({'jsonrpc': '2.0', 'id': id, 'result': result});

  void _respondError(Object id, int code, String message) =>
      _write({
        'jsonrpc': '2.0',
        'id': id,
        'error': {'code': code, 'message': message},
      });

  void _write(Map<String, dynamic> message) {
    _output.writeln(jsonEncode(message));
  }

  void _log(String message) => stderr.writeln('[mcp:$name] $message');
}

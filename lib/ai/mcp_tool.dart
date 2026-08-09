import 'dart:async';

/// One callable tool in the MCP tool registry. The AI copilot can invoke tools
/// by name; the tool's [execute] method does the actual work in trusted Dart.
///
/// Tools are **deterministic** — the model decides *what* to call, but the
/// execution is always done by the application core, never by the model.
///
/// Subclass this to create a tool, then register it with [McpToolRegistry].
abstract class McpTool {
  /// Unique tool name (e.g. `'compute_route'`, `'get_airport'`).
  String get name;

  /// Human / model readable description of what the tool does.
  String get description;

  /// JSON-schema-style parameter definition. The model uses this to format its
  /// tool-call arguments.
  Map<String, dynamic> get inputSchema;

  /// Whether this tool requires explicit user confirmation before executing.
  /// Read-only tools (navdata lookup, weather) should return `false`; write
  /// tools (export, simulator command) should return `true`.
  bool get requiresConfirmation;

  /// Executes the tool with the model-supplied [arguments]. Returns a result
  /// map that is sent back to the model as the tool response.
  Future<Map<String, dynamic>> execute(Map<String, dynamic> arguments);
}

/// Central registry for all MCP tools available to the AI copilot. Populated
/// during app startup (Phase 2+) as each feature registers its tools.
class McpToolRegistry {
  McpToolRegistry();

  final Map<String, McpTool> _tools = {};

  /// Registers a tool. If a tool with the same name already exists, it is
  /// replaced.
  void register(McpTool tool) {
    _tools[tool.name] = tool;
  }

  /// Looks up a tool by name.
  McpTool? operator [](String name) => _tools[name];

  /// All registered tools (for listing available tools to the model).
  List<McpTool> get all => _tools.values.toList(growable: false);

  /// Returns a JSON list of tool definitions suitable for sending to an LLM
  /// as the available function-calling schema.
  List<Map<String, dynamic>> toJsonList() => all
      .map(
        (t) => {
          'type': 'function',
          'function': {
            'name': t.name,
            'description': t.description,
            'parameters': t.inputSchema,
          },
        },
      )
      .toList();
}

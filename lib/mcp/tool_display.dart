import '../l10n/app_localizations.dart';

/// Readable display helpers for tool calls on permission cards and phase
/// rows — the raw wire names (`get_airport_data`,
/// `mcp__flightstudio-core__get_airport_data`) never surface to the user.
///
/// The name mapping covers every tool registered in the gateway's safety
/// ladder (agent_gateway/src/safety_policy_guard.ts); the key-parameter
/// list covers the tools the Dart MCP server implements
/// (lib/mcp/core_tools.dart). Unknown tools fall back to their bare
/// (unqualified) name and a generic value-only parameter marker.

/// Key parameters per registered FlightStudio Core tool — the values shown
/// as a marker next to the readable name, value-only (never `key: value`).
const Map<String, List<String>> _keyParams = {
  'get_airport_data': ['icao'],
  'charts_read': ['icao'],
  'weather_read': ['icao'],
};

/// Longest value shown in the marker before clipping.
const _paramValueMaxChars = 16;

/// Strips MCP qualification: `mcp__flightstudio-core__get_airport_data`
/// → `get_airport_data`. Non-MCP names pass through unchanged.
String bareToolName(String raw) {
  final name = raw.trim();
  if (name.length >= 5 && name.substring(0, 5).toLowerCase() == 'mcp__') {
    final parts = name.split('__');
    if (parts.length >= 3) return parts.sublist(2).join('__');
  }
  return name;
}

/// Localized readable name for a tool call: registered FlightStudio Core
/// tools map to translated labels; anything else falls back to the bare
/// (unqualified) tool name.
String toolDisplayName(String rawTool, AppLocalizations l10n) {
  switch (bareToolName(rawTool).toLowerCase()) {
    case 'get_airport_data':
      return l10n.mcpToolAirportData;
    case 'charts_read':
      return l10n.mcpToolChartsRead;
    case 'weather_read':
      return l10n.mcpToolWeatherRead;
    case 'search_navdata':
      return l10n.mcpToolSearchNavdata;
    case 'search_manual':
      return l10n.mcpToolSearchManual;
    case 'get_sim_state':
      return l10n.mcpToolSimState;
    case 'propose_action_plan':
      return l10n.mcpToolActionPlan;
    case 'render_map':
      return l10n.mcpToolRenderMap;
    case 'set_com_frequency':
      return l10n.mcpToolSetComFrequency;
    case 'send_sim_command':
      return l10n.mcpToolSendSimCommand;
    default:
      return bareToolName(rawTool);
  }
}

/// The important parameter VALUES of a tool call, in declaration order —
/// shown next to the readable name, value-only (no parameter names).
/// Registered tools list their key parameters; everything else shows the
/// first few scalar values generically. Clipped per value.
List<String> toolKeyParams(String rawTool, Map<String, dynamic> input) {
  final keys = _keyParams[bareToolName(rawTool).toLowerCase()];
  if (keys != null) {
    return [for (final k in keys) ?_scalarText(input[k])];
  }
  return [for (final e in input.entries.take(3)) ?_scalarText(e.value)];
}

/// Whether the key-parameter marker already shows every input entry — the
/// card then omits the redundant `key: value` preview box.
bool keyParamsCoverInput(String rawTool, Map<String, dynamic> input) {
  final keys = _keyParams[bareToolName(rawTool).toLowerCase()];
  return keys != null && input.keys.every((k) => keys.contains(k));
}

String? _scalarText(Object? value) {
  if (value is Map || value is List) return null;
  final text = '$value'.trim();
  if (text.isEmpty) return null;
  return text.length > _paramValueMaxChars
      ? '${text.substring(0, _paramValueMaxChars)}…'
      : text;
}

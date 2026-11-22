import 'dart:io';

import 'package:flight_studio/mcp/core_tools.dart';
import 'package:flight_studio/mcp/stdio_server.dart';

/// FlightStudio Core — the app's stdio MCP server, spawned by the Agent
/// Gateway and consumed by the flight-assistant agent. Owns every tool that
/// controls/inspects FlightStudio; this first milestone ships the L1
/// read-only aeronautical set (airport dossier, charts, weather).
///
/// Configuration (environment):
/// - FLIGHTSTUDIO_NAVDATA_DB — path of the app's navdata SQLite database
///   (opened READ-ONLY; the app remains the sole writer).
/// - CHARTFOX_TOKEN          — optional ChartFox bearer token.
/// - FLIGHTSTUDIO_XPLANE_PORT — X-Plane Web API port for `get_sim_state`
///   (default 8086).
///
/// Tool invocations are audited into `mcp-audit.sqlite` next to the
/// navdata database.
Future<void> main() async {
  final navdataDb = Platform.environment['FLIGHTSTUDIO_NAVDATA_DB'] ?? '';
  final toolServer = CoreToolServer(navdataDbPath: navdataDb);
  final server = McpStdioServer(
    name: 'flightstudio-core',
    version: '0.1.0',
    toolServer: toolServer,
  );
  try {
    await server.run();
  } finally {
    toolServer.dispose();
  }
}

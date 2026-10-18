// FlightStudio Core MCP server — tool registry, airport dossier from a
// scratch in-memory navdata database, the safety ladder metadata, audit
// logging and the stdio JSON-RPC layer.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flight_studio/mcp/audit_log.dart';
import 'package:flight_studio/mcp/core_tools.dart';
import 'package:flight_studio/mcp/stdio_server.dart';
import 'package:sqlite3/sqlite3.dart';

CoreToolServer _serverWithScratchDb({String auditPath = ''}) {
  final db = sqlite3.openInMemory();
  db.execute('''
    CREATE TABLE airports (
      icao TEXT PRIMARY KEY, iata TEXT, name TEXT, city TEXT, country TEXT,
      latitude REAL, longitude REAL, elevation_ft REAL, magvar_deg REAL,
      type TEXT, source TEXT)
  ''');
  db.execute('''
    CREATE TABLE runways (
      airport_icao TEXT, ident TEXT, latitude REAL, longitude REAL,
      length_ft REAL, width_ft REAL, heading_deg REAL, surface TEXT,
      edge_lights TEXT, strip_index INTEGER,
      PRIMARY KEY (airport_icao, ident))
  ''');
  db.execute('''
    CREATE TABLE frequencies (
      airport_icao TEXT, type TEXT, frequency_khz INTEGER, description TEXT)
  ''');
  db.execute(
    "INSERT INTO airports VALUES ('ZBAA', 'PEK', '首都国际机场', '北京', '中国', "
    '40.08, 116.58, 116.0, -7.0, '
    "'airport', 'xplane')");
  for (final (ident, heading, strip) in [
    ('01', 5.0, 0),
    ('19', 185.0, 0),
    ('18L', 175.0, 1),
    ('36R', 355.0, 1),
  ]) {
    db.execute(
      'INSERT INTO runways VALUES (?, ?, 0, 0, 12008, 148, ?, NULL, NULL, ?)',
      ['ZBAA', ident, heading, strip],
    );
  }
  db.execute(
    "INSERT INTO frequencies VALUES ('ZBAA', 'TWR', 118500, 'Tower')",
  );
  db.execute(
    "INSERT INTO frequencies VALUES ('ZBAA', 'ATIS', 127600, NULL)",
  );
  // Persist to a temp file so the read-only server can open it
  // (VACUUM INTO, supported by sqlite ≥ 3.27).
  final dir = Directory.systemTemp.createTempSync('fs_mcp_test');
  final path = '${dir.path}${Platform.pathSeparator}navdata.sqlite';
    db.execute("VACUUM INTO '$path'");
    db.close();
  return CoreToolServer(
    navdataDbPath: path,
    auditLog: auditPath.isEmpty ? null : McpAuditLog.open(auditPath),
  );
}

void main() {
  test('registry exposes the three L1 aeronautical tools', () {
    final server = _serverWithScratchDb();
    addTearDown(server.dispose);
    final names = server.tools.map((t) => t.name).toList();
    expect(names, containsAll(['get_airport_data', 'charts_read', 'weather_read']));
    for (final t in server.tools) {
      expect(t.level, SafetyLevel.publicData);
      expect(t.schema['type'], 'object');
    }
    // MCP-qualified lookup.
    expect(
      server.toolByName('mcp__flightstudio-core__get_airport_data')?.name,
      'get_airport_data',
    );
    expect(server.toolByName('nope'), isNull);
  });

  test('get_airport_data returns the full dossier', () async {
    final server = _serverWithScratchDb();
    addTearDown(server.dispose);
    final result = await server.invoke(
      server.tools.firstWhere((t) => t.name == 'get_airport_data'),
      {'icao': 'zbaa'},
    );
    expect(result, contains('ZBAA'));
    expect(result, contains('首都国际机场'));
    expect(result, contains('118.50 MHz')); // TWR
    expect(result, contains('ATIS: 127.60 MHz'));
    // Runway ends grouped into strips: 01/19 and 18L/36R.
    expect(result, contains('01/19'));
    expect(result, contains('18L/36R'));
    expect(result, contains('3,660 m')); // 12008 ft → metres
  });

  test('get_airport_data rejects unknown ICAO / invalid codes', () async {
    final server = _serverWithScratchDb();
    addTearDown(server.dispose);
    final tool = server.tools.firstWhere((t) => t.name == 'get_airport_data');
    expect(await tool.execute({'icao': 'ZZZZ'}), contains('No airport found'));
    expect(await tool.execute({'icao': '..'}), contains('Invalid ICAO'));
    expect(
      await server.invoke(tool, {'icao': ''}),
      contains('Invalid ICAO'),
    );
  });

  test('audit log records every invocation', () async {
    final dir = Directory.systemTemp.createTempSync('fs_audit_test');
    final auditPath = '${dir.path}${Platform.pathSeparator}audit.sqlite';
    final server = _serverWithScratchDb(auditPath: auditPath);
    addTearDown(server.dispose);
    final tool = server.tools.firstWhere((t) => t.name == 'get_airport_data');
    await server.invoke(tool, {'icao': 'ZBAA'});
    final rows = McpAuditLog.open(auditPath).readAll();
    expect(rows, hasLength(1));
    expect(rows.first['tool'], 'get_airport_data');
    expect(rows.first['level'], 1);
    expect(rows.first['ok'], 1);
    expect('${rows.first['args_json']}', contains('ZBAA'));
    expect('${rows.first['result_summary']}', contains('首都国际机场'));
  });

  test('stdio server speaks the MCP JSON-RPC subset', () async {
    final dir = Directory.systemTemp.createTempSync('fs_stdio_test');
    final auditPath = '${dir.path}${Platform.pathSeparator}audit.sqlite';
    final server = _serverWithScratchDb(auditPath: auditPath);
    addTearDown(server.dispose);
    final out = StringBuffer();
    final mcp = McpStdioServer(
      name: 'flightstudio-core',
      version: '0.1.0',
      toolServer: server,
      input: Stream.fromIterable([
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'initialize',
          'params': {'protocolVersion': '2025-06-18'},
        }),
        jsonEncode({'jsonrpc': '2.0', 'method': 'notifications/initialized'}),
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 2,
          'method': 'tools/list',
        }),
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 3,
          'method': 'tools/call',
          'params': {
            'name': 'get_airport_data',
            'arguments': {'icao': 'ZBAA'},
          },
        }),
      ]),
      output: out,
    );
    await mcp.run();

    final replies = out
        .toString()
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .map((l) => jsonDecode(l) as Map<String, dynamic>)
        .toList();
    expect(replies, hasLength(3)); // notifications get no reply

    final init = replies[0];
    expect(init['id'], 1);
    expect(
      (init['result'] as Map)['serverInfo'],
      containsPair('name', 'flightstudio-core'),
    );

    final list = replies[1];
    final tools = (list['result'] as Map)['tools'] as List;
    expect(tools.map((t) => (t as Map)['name']), contains('get_airport_data'));

    final call = replies[2];
    final content = ((call['result'] as Map)['content'] as List).first
        as Map<String, dynamic>;
    expect(content['type'], 'text');
    expect('${content['text']}', contains('首都国际机场'));
    expect((call['result'] as Map)['isError'], false);
  });
}

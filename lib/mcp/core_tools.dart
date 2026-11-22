import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:sqlite3/sqlite3.dart';

import '../data/navdata/airport_details.dart';
import '../data/weather/weather_service.dart';
import 'audit_log.dart';

/// FlightStudio safety ladder — how much of the app an AI tool may touch.
///
/// The ladder has exactly four rungs (there are deliberately no L4/L5
/// "auto-execute" rungs — every write requires explicit user approval):
/// - L0 — every tool call waits for the manual approval card (the most
///   conservative interactive level; nothing runs unattended)
/// - L1 — public read-only aeronautical data (airports, runways,
///   frequencies, weather, charts) auto-runs, everything else waits
/// - L2 — app-state reads (flight plans, settings overview, telemetry)
/// - L3 — writes behind explicit user confirmation
///
/// This mirrors the gateway's authoritative ladder in
/// agent_gateway/src/safety_policy_guard.ts (policy v5).
class SafetyLevel {
  static const int nothing = 0;
  static const int publicData = 1;
  static const int appStateRead = 2;
  static const int confirmedWrite = 3;

  /// Upper bound of the ladder; levels above this are invalid.
  static const int max = confirmedWrite;

  /// Human-readable label for a level ([0, max]).
  static String label(int level) => switch (level) {
        0 => 'L0 (manual approval for every call)',
        1 => 'L1 (public aeronautical data)',
        2 => 'L2 (app-state reads)',
        3 => 'L3 (confirmed writes)',
        _ => 'invalid level $level',
      };

  /// Whether [level] is a valid ladder rung.
  static bool isValid(int level) => level >= nothing && level <= max;
}

/// One FlightStudio Core tool exposed over MCP.
class CoreTool {
  const CoreTool({
    required this.name,
    required this.description,
    required this.schema,
    required this.level,
    required this.execute,
  });

  final String name;
  final String description;

  /// JSON Schema (object) describing the tool's arguments.
  final Map<String, dynamic> schema;

  /// Safety ladder level ([SafetyLevel]); the gateway refuses calls above
  /// the user's granted level.
  final int level;

  final Future<String> Function(Map<String, dynamic> args) execute;
}

/// Owns the read-only navdata connection and builds the FlightStudio Core
/// tool registry: everything the flight-assistant agent may call to inspect
/// FlightStudio's aeronautical data. L1 only in this first milestone.
class CoreToolServer {
  CoreToolServer({required this.navdataDbPath, McpAuditLog? auditLog})
      : _audit = auditLog ?? McpAuditLog.open(
          McpAuditLog.derivePath(navdataDbPath),
        );

  /// Path of the app's navdata SQLite database (read-only here).
  final String navdataDbPath;
  final McpAuditLog _audit;

  Database? _db;

  Database? _open() {
    if (navdataDbPath.isEmpty) return null;
    if (!File(navdataDbPath).existsSync()) return null;
    _db ??= sqlite3.open(navdataDbPath, mode: OpenMode.readOnly);
    return _db;
  }

  /// The FlightStudio Core tool registry.
  List<CoreTool> get tools => [
        CoreTool(
          name: 'get_airport_data',
          description: 'Full airport dossier for one ICAO (the inspector '
              'view): identity, coordinates, elevation, magnetic variation, '
              'all runway strips (paired ends, dimensions, surface), all ATC '
              'frequencies and the live METAR + TAF. Use for any airport '
              'question (机场/跑道/频率/天气).',
          schema: const {
            'type': 'object',
            'properties': {
              'icao': {
                'type': 'string',
                'description': 'ICAO identifier, e.g. ZBAA',
              },
            },
            'required': ['icao'],
          },
          level: SafetyLevel.publicData,
          execute: _getAirportData,
        ),
        CoreTool(
          name: 'charts_read',
          description: 'List available airport charts (ground/taxi/departure/'
              'arrival/approach) for one ICAO via ChartFox. Use when the '
              'pilot asks for 航图/charts.',
          schema: const {
            'type': 'object',
            'properties': {
              'icao': {'type': 'string', 'description': 'ICAO identifier'},
            },
            'required': ['icao'],
          },
          level: SafetyLevel.publicData,
          execute: _chartsRead,
        ),
        CoreTool(
          name: 'weather_read',
          description: 'Fetch the current METAR and TAF raw reports for one '
              'ICAO. Use for 天气/weather questions about a specific airport.',
          schema: const {
            'type': 'object',
            'properties': {
              'icao': {'type': 'string', 'description': 'ICAO identifier'},
            },
            'required': ['icao'],
          },
          level: SafetyLevel.publicData,
          execute: _weatherRead,
        ),
        CoreTool(
          name: 'get_sim_state',
          description: 'Live aircraft state from X-Plane\'s local Web API: '
              'position, altitude (MSL/AGL), speeds (IAS/TAS/GS/VS), '
              'headings, attitude and the autopilot windows. Use for any '
              'question about where the aircraft is or how it is flying '
              '(飞机状态/高度/速度/航向/自动驾驶). Returns a hint when no '
              'simulator is reachable.',
          schema: const {
            'type': 'object',
            'properties': <String, dynamic>{},
          },
          level: SafetyLevel.publicData,
          execute: _getSimState,
        ),
      ];

  /// Finds a registered tool by name (or by an MCP-qualified suffix like
  /// `mcp__flightstudio-core__get_airport_data`).
  CoreTool? toolByName(String raw) {
    final name = raw.trim().toLowerCase();
    for (final t in tools) {
      if (name == t.name || name.endsWith('__${t.name}')) return t;
    }
    return null;
  }

  /// Wraps an execution with the audit trail. Fails closed for tools at
  /// L2 or above when the audit trail itself is unavailable — an
  /// unaudited write (or app-state read) must never silently run.
  Future<String> invoke(CoreTool tool, Map<String, dynamic> args) async {
    if (tool.level >= SafetyLevel.appStateRead &&
        !_audit.isAvailable) {
      return 'Tool "${tool.name}" (L${tool.level}) requires the audit '
          'trail, which is unavailable — refusing to run. '
          'Restart the app or check mcp-audit.sqlite.';
    }
    final sw = Stopwatch()..start();
    try {
      final result = await tool.execute(args);
      sw.stop();
      _audit.record(
        tool: tool.name,
        level: tool.level,
        args: args,
        ok: true,
        resultSummary: result,
        duration: sw.elapsed,
      );
      return result;
    } on Exception catch (e) {
      sw.stop();
      _audit.record(
        tool: tool.name,
        level: tool.level,
        args: args,
        ok: false,
        resultSummary: 'error: $e',
        duration: sw.elapsed,
      );
      rethrow;
    }
  }

  // ── get_airport_data ──────────────────────────────────────────────────────

  Future<String> _getAirportData(Map<String, dynamic> args) async {
    final icao = (args['icao'] as String? ?? '').trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{2,6}$').hasMatch(icao)) {
      return 'Invalid ICAO: "$icao"';
    }
    final db = _open();
    if (db == null) {
      return 'Navdata database unavailable '
          '${navdataDbPath.isEmpty ? '(no path configured)' : '($navdataDbPath)'}. '
          'Import navigation data first.';
    }

    final row = _single(
      db,
      'SELECT icao, iata, name, city, country, latitude, longitude, '
      'elevation_ft, magvar_deg, type, source FROM airports WHERE icao = ?',
      [icao],
    );
    if (row == null) {
      return 'No airport found for ICAO $icao in the navdata database.';
    }

    final runways = db.select(
      'SELECT ident, heading_deg, length_ft, width_ft, surface, strip_index '
      'FROM runways WHERE airport_icao = ? ORDER BY ident',
      [icao],
    );
    final freqs = db.select(
      'SELECT type, frequency_khz, description FROM frequencies '
      'WHERE airport_icao = ? ORDER BY type, frequency_khz',
      [icao],
    );

    final strips = groupRunwayStrips([
      for (final r in runways)
        RunwayDetails(
          ident: r['ident'] as String,
          headingDeg: r['heading_deg'] as double,
          lengthFt: r['length_ft'] as double,
          widthFt: r['width_ft'] as double?,
          surface: r['surface'] as String?,
          stripIndex: r['strip_index'] as int?,
        ),
    ]);

    final b = StringBuffer();
    String? s(String key) => row[key] == null ? null : '${row[key]}';
    b.writeln('## $icao — ${row['name']}');
    final place = [s('city'), s('country')].whereType<String>().join(', ');
    b.writeln(place.isEmpty ? '' : '$place  ');
    b.writeln('- IATA: ${s('iata') ?? '—'}');
    b.writeln('- Type: ${s('type')}  ·  Data source: ${s('source')}');
    b.writeln('- Position: ${(row['latitude'] as double).toStringAsFixed(5)}, '
        '${(row['longitude'] as double).toStringAsFixed(5)}');
    b.writeln('- Elevation: ${s('elevation_ft') ?? '—'} ft'
        '${row['magvar_deg'] == null ? '' : '  ·  Magvar: ${s('magvar_deg')}°'}');
    b.writeln();
    b.writeln('### Frequencies');
    if (freqs.isEmpty) {
      b.writeln('(none)');
    } else {
      for (final f in freqs) {
        final khz = f['frequency_khz'] as int;
        final mhz = (khz / 1000).toStringAsFixed(2);
        final desc = f['description'] as String?;
        b.writeln('- ${f['type']}: $mhz MHz'
            '${desc == null || desc.isEmpty ? '' : ' · $desc'}');
      }
    }
    b.writeln();
    b.writeln('### Runways (${strips.length} strip(s))');
    if (strips.isEmpty) {
      b.writeln('(none)');
    } else {
      String m(double ft) =>
          (ft * 0.3048).round().toString().replaceAllMapped(
                RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                (m) => '${m[1]},',
              );
      for (final strip in strips) {
        final idents = strip.map((r) => r.ident).join('/');
        final first = strip.first;
        final dims = first.widthFt != null
            ? '${m(first.lengthFt)} m × $m(first.widthFt!) m'
            : '${m(first.lengthFt)} m';
        final surface =
            first.surface == null || first.surface!.isEmpty
            ? ''
            : ' · ${first.surface}';
        b.writeln('- $idents: $dims$surface');
      }
    }

    // Live weather — best-effort; omit section when unavailable.
    final weather = await WeatherService.instance.fetch(icao);
    if (weather != null) {
      b.writeln();
      b.writeln('### Weather');
      if (weather.metar != null) b.writeln('METAR: ${weather.metar}');
      if (weather.taf != null) b.writeln('TAF: ${weather.taf}');
    }
    return b.toString().trim();
  }

  Row? _single(
    Database db,
    String sql,
    List<Object?> params,
  ) {
    final rows = db.select(sql, params);
    return rows.isEmpty ? null : rows.first;
  }

  // ── get_sim_state ─────────────────────────────────────────────────────────
  // Reads X-Plane's local Web API over REST on demand (probe → name→id
  // resolve, cached per process → value reads). The MCP server is its own
  // process, so it talks to the sim directly rather than through the app's
  // SimConnectionService. Port comes from FLIGHTSTUDIO_XPLANE_PORT
  // (default 8086).

  /// Session-scoped dataref ids resolved from names (stable within one
  /// X-Plane run).
  static Map<String, int>? _simStateIds;

  static const _simStateNames = <String, String>{
    'lat': 'sim/flightmodel/position/latitude',
    'lon': 'sim/flightmodel/position/longitude',
    'elevM': 'sim/flightmodel/position/elevation',
    'aglFt': 'sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot',
    'gsMs': 'sim/flightmodel/position/groundspeed',
    'iasKt': 'sim/flightmodel/position/indicated_airspeed',
    'tasKt': 'sim/flightmodel/position/true_airspeed',
    'vsFpm': 'sim/flightmodel/position/vh_ind',
    'hdgTrue': 'sim/flightmodel/position/psi',
    'hdgMag': 'sim/cockpit2/gauges/indicators/heading_AHARS_deg_mag_pilot',
    'pitch': 'sim/flightmodel/position/theta',
    'roll': 'sim/flightmodel/position/phi',
    'apServos': 'sim/cockpit2/autopilot/servos_on',
    'apAltFt': 'sim/cockpit2/autopilot/altitude_dial_ft',
    'apHdg': 'sim/cockpit2/autopilot/heading_dial_deg',
    'apSpdKt': 'sim/cockpit2/autopilot/airspeed_dial_kias',
  };

  static Dio? _simDio;

  static Dio get _simRest => _simDio ??= Dio()
    ..options.connectTimeout = const Duration(seconds: 3)
    ..options.receiveTimeout = const Duration(seconds: 4);

  static int get _simPort =>
      int.tryParse(Platform.environment['FLIGHTSTUDIO_XPLANE_PORT'] ?? '') ??
      8086;

  Future<String> _getSimState(Map<String, dynamic> args) async {
    final port = _simPort;
    final base = 'http://127.0.0.1:$port';
    // Probe — a clean refusal text beats a stack of timeouts downstream.
    try {
      await _simRest.get<Map<String, dynamic>>('$base/api/capabilities');
    } on Exception {
      return 'X-Plane Web API unreachable on 127.0.0.1:$port. The simulator '
          'must be running (X-Plane 12.1.1+) with incoming traffic allowed '
          '(Settings → Network).';
    }
    try {
      _simStateIds ??= await _resolveSimDatarefs(base);
      final ids = _simStateIds!;
      final values = <String, num>{};
      for (final entry in ids.entries) {
        final res = await _simRest.get<dynamic>(
          '$base/api/v3/datarefs/${entry.value}/value',
        );
        final data = res.data is Map ? (res.data as Map)['data'] : res.data;
        if (data is num) {
          values[entry.key] = data;
        } else if (data is List && data.isNotEmpty && data.first is num) {
          values[entry.key] = data.first as num;
        }
      }
      if (!values.containsKey('lat') || !values.containsKey('lon')) {
        return 'No flight loaded in X-Plane (no position datarefs yet).';
      }
      double? v(String k) => values[k]?.toDouble();
      String fmt(String k, String unit, {int digits = 1}) =>
          v(k) == null ? '—' : '${v(k)!.toStringAsFixed(digits)}$unit';
      final apOn = v('apServos');
      final b = StringBuffer('## Aircraft state');
      b.writeln();
      b.writeln('- Position: ${v('lat')!.toStringAsFixed(4)}, '
          '${v('lon')!.toStringAsFixed(4)}');
      b.writeln('- Altitude: ${fmt('elevM', ' ft MSL', digits: 0)}'
          ' · ${fmt('aglFt', ' ft AGL', digits: 0)}');
      b.writeln('- Speeds: IAS ${fmt('iasKt', ' kt')} · TAS '
          '${fmt('tasKt', ' kt')} · GS '
          '${v('gsMs') == null ? '—' : '${(v('gsMs')! * 1.94384).toStringAsFixed(1)} kt'}'
          ' · VS ${fmt('vsFpm', ' fpm', digits: 0)}');
      b.writeln('- Heading: true ${fmt('hdgTrue', '°')} · magnetic '
          '${fmt('hdgMag', '°')}');
      b.writeln('- Attitude: pitch ${fmt('pitch', '°')} · roll '
          '${fmt('roll', '°')}');
      b.writeln('- Autopilot: ${apOn == null ? 'unknown' : (apOn != 0 ? 'ENGAGED' : 'OFF')}'
          ' · alt ${fmt('apAltFt', ' ft', digits: 0)} · hdg '
          '${fmt('apHdg', '°')} · spd ${fmt('apSpdKt', ' kt')}');
      return b.toString().trim();
    } on Exception catch (e) {
      return 'Sim state read failed: $e';
    }
  }

  /// Resolves the sim-state dataref names to session ids (one REST query
  /// per name; unresolved names are skipped — aircraft dataref sets vary).
  static Future<Map<String, int>> _resolveSimDatarefs(String base) async {
    final out = <String, int>{};
    for (final entry in _simStateNames.entries) {
      try {
        final res = await _simRest.get<Map<String, dynamic>>(
          '$base/api/v3/datarefs',
          queryParameters: {
            'filter[name]': entry.value,
            'fields': 'id,name',
          },
        );
        final list = res.data?['data'];
        if (list is! List || list.isEmpty) continue;
        for (final row in list) {
          if (row is Map<String, dynamic> && row['name'] == entry.value) {
            final id = row['id'];
            if (id is int) out[entry.key] = id;
            break;
          }
        }
      } on Exception {
        // Unresolved on this aircraft — skip.
      }
    }
    return out;
  }

  // ── charts_read ───────────────────────────────────────────────────────────

  Future<String> _chartsRead(Map<String, dynamic> args) async {
    final icao = (args['icao'] as String? ?? '').trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{2,6}$').hasMatch(icao)) {
      return 'Invalid ICAO: "$icao"';
    }
    try {
      final dio = Dio()
        ..options.connectTimeout = const Duration(seconds: 8)
        ..options.receiveTimeout = const Duration(seconds: 10);
      final token = Platform.environment['CHARTFOX_TOKEN'] ?? '';
      final res = await dio.get<String>(
        'https://api.chartfox.org/v2/airport/$icao',
        options: Options(
          headers: token.isEmpty ? null : {'Authorization': 'Bearer $token'},
        ),
      );
      final data = jsonDecode(res.data ?? '{}') as Map<String, dynamic>;
      final groups = (data['groups'] as List?) ?? const [];
      final lines = <String>[];
      for (final g in groups) {
        final gm = g as Map<String, dynamic>;
        for (final c in (gm['charts'] as List?) ?? const []) {
          final cm = c as Map<String, dynamic>;
          lines.add('[${gm['group'] ?? '?'}] '
              '${cm['name'] ?? 'chart'} — ${cm['url'] ?? ''}');
        }
      }
      return lines.isEmpty
          ? 'No charts found for $icao'
          : 'Charts for $icao:\n${lines.join('\n')}';
    } on Exception catch (e) {
      return 'ChartFox request failed: $e';
    }
  }

  // ── weather_read ──────────────────────────────────────────────────────────

  Future<String> _weatherRead(Map<String, dynamic> args) async {
    final icao = (args['icao'] as String? ?? '').trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{4}$').hasMatch(icao)) {
      return 'Invalid ICAO: "$icao"';
    }
    try {
      final dio = Dio()
        ..options.connectTimeout = const Duration(seconds: 8)
        ..options.receiveTimeout = const Duration(seconds: 10);
      final metar = (await dio.get<String>(
        'https://aviationweather.gov/api/data/metar',
        queryParameters: {'ids': icao, 'format': 'raw'},
      )).data?.trim();
      String taf = '(TAF unavailable)';
      try {
        taf = (await dio.get<String>(
          'https://aviationweather.gov/api/data/taf',
          queryParameters: {'ids': icao, 'format': 'raw'},
        )).data?.trim() ?? taf;
      } on Exception {
        // Keep the placeholder.
      }
      return 'METAR $icao:\n${metar ?? '(none)'}\n\nTAF $icao:\n$taf';
    } on Exception catch (e) {
      return 'Weather request failed: $e';
    }
  }

  void dispose() {
    _db?.close();
    _audit.dispose();
  }
}

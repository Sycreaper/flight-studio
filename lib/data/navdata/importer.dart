import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/navdata/navdata_types.dart';
import '../../../core/parsing/apt_dat_parser.dart' as apt;
import '../../../data/db/database.dart';
import 'airport_details.dart';
import 'db_opener.dart';

typedef ProgressCallback =
    void Function(int current, int total, String message);

/// Intermediate type for map markers derived from DB rows.
class MapPoint {
  const MapPoint({
    required this.category,
    required this.ident,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.frequency,
    this.elevationFt,
  });

  final NavPointCategory category;
  final String ident;
  final String name;
  final double latitude;
  final double longitude;
  final String? frequency;
  final int? elevationFt;
}

/// Result of a navdata import run.
class NavdataImportResult {
  const NavdataImportResult({
    required this.navaids,
    required this.fixes,
    required this.airways,
    this.airports = 0,
  });

  final int navaids;
  final int fixes;
  final int airways;
  final int airports;

  int get total => navaids + fixes + airways + airports;

  @override
  String toString() =>
      'NavdataImportResult(navaids=$navaids, '
      'fixes=$fixes, airways=$airways, airports=$airports)';
}

/// Manages the navdata import pipeline.
class NavdataImporter {
  NavdataImporter();

  NavdataDatabase? _db;
  final Set<String> _knownAptIcaos = {};

  NavdataDatabase? get database => _db;

  /// Test-only: attaches an already-open database so query methods can be
  /// exercised without touching the real on-disk store.
  set attachForTest(NavdataDatabase db) => _db = db;

  /// Opens (or creates) the navdata database in the app support directory and
  /// clears all tables. Call once before running the per-file parsers.
  ///
  /// Also creates lat/lon indexes after clearing so viewport queries stay
  /// fast even with 250k+ waypoint rows.
  Future<NavdataDatabase> openAndClear({ProgressCallback? onProgress}) async {
    final db = await _openDb();
    onProgress?.call(0, 1, 'Clearing database…');
    await db.delete(db.airports).go();
    await db.delete(db.runways).go();
    await db.delete(db.frequencies).go();
    await db.delete(db.navaids).go();
    await db.delete(db.fixes).go();
    await db.delete(db.airways).go();
    _knownAptIcaos.clear();

    onProgress?.call(0, 1, 'Creating indexes…');
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_airports_lat_lon ON airports (latitude, longitude)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_navaids_lat_lon ON navaids (latitude, longitude)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_fixes_lat_lon ON fixes (latitude, longitude)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_airports_icao ON airports (icao)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_navaids_ident ON navaids (ident)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_fixes_ident ON fixes (ident)',
    );
    return db;
  }

  Future<NavdataDatabase> _openDb() async {
    if (_db != null) return _db!;
    final dir = await getApplicationSupportDirectory();
    _db = openNavdataDatabase(p.join(dir.path, 'navdata.sqlite'));
    return _db!;
  }

  /// Resolves which data subfolder of [installPath] to read nav files from —
  /// prefers `Custom Data` when it contains `earth_nav.dat`, otherwise falls
  /// back to `Resources/default data`.
  Future<String> resolveDataDir(String installPath) async {
    final custom = p.join(installPath, 'Custom Data');
    if (await File(p.join(custom, 'earth_nav.dat')).exists()) {
      return 'Custom Data';
    }
    return p.join('Resources', 'default data');
  }

  /// Discovers ALL airport `apt.dat` files inside an X-Plane install, in
  /// **Little Navmap's order**: global airports first, then custom scenery
  /// packs — so custom airports can override global ones on conflict.
  ///
  /// LNM logic (atools `scenerypacks.cpp` + XP12 conventions):
  /// - Global: `Global Scenery/Global Airports/Earth nav data/apt.dat`
  ///   (XP12) — also accepts `Resources/default scenery/...` (XP11) and
  ///   `Custom Scenery/Global Airports/...` (XP11).
  /// - Customs: every subfolder of `Custom Scenery/` that has
  ///   `Earth nav data/apt.dat`.
  Future<List<File>> discoverAptFiles(String installPath) async {
    final files = <File>[];
    final root = installPath.replaceAll('\\', '/');

    // 1. Global airports (XP12 layout, then XP11 fallbacks).
    final globals = [
      '$root/Global Scenery/Global Airports/Earth nav data/apt.dat',
      '$root/Custom Scenery/Global Airports/Earth nav data/apt.dat',
      '$root/Resources/default scenery/Airport Scenery/default apt dat/apt.dat',
    ];
    for (final g in globals) {
      final f = File(g);
      if (await f.exists()) {
        files.add(f);
        break; // Only one global file.
      }
    }

    // 2. Custom Scenery packs — any folder with Earth nav data/apt.dat.
    final customScenery = Directory('$root/Custom Scenery');
    if (await customScenery.exists()) {
      await for (final pack in customScenery.list()) {
        if (pack is! Directory) continue;
        if (pack.path.endsWith('Global Airports')) continue; // Already added.
        final apt = File(
          '${pack.path.replaceAll('\\', '/')}/Earth nav data/apt.dat',
        );
        if (await apt.exists()) files.add(apt);
      }
    }

    return files;
  }

  /// Imports airports + runways from multiple apt.dat files. Global file
  /// first (insertOrIgnore), customs after (insertOrReplace) so pack airports
  /// override global ones — mirroring LNM's precedence.
  Future<int> importAptFiles(
    List<File> files,
    NavdataDatabase db, {
    ProgressCallback? onProgress,
  }) async {
    var total = 0;
    for (var i = 0; i < files.length; i++) {
      final isGlobal = i == 0;
      total += await apt.importAptDat(
        files[i],
        db,
        onProgress: onProgress == null
            ? null
            : (c, t, m) => onProgress(c, t, '$m (${i + 1}/${files.length})'),
        replace: !isGlobal,
      );
    }
    return total;
  }

  /// Resolves the single global airports `apt.dat` (legacy single-file path).
  Future<File?> resolveAptDat(String installPath) async {
    final files = await discoverAptFiles(installPath);
    return files.isEmpty ? null : files.first;
  }

  // ── Queries ─────────────────────────────────────────────────────────────

  /// Builds a raw SQL ordering term that sorts by squared distance from
  /// (lat, lon) — closest first. This is what makes marker distribution
  /// correct at every pan/zoom position instead of showing only
  /// alphabetically-early rows.
  static OrderingTerm _distanceOrder(double lat, double lon) {
    // Values are clamped doubles we produce ourselves — safe to interpolate.
    final la = lat.clamp(-90.0, 90.0).toStringAsFixed(6);
    final lo = lon.clamp(-180.0, 180.0).toStringAsFixed(6);
    return OrderingTerm.asc(
      CustomExpression<double>(
        '((latitude - $la) * (latitude - $la) + (longitude - $lo) * (longitude - $lo))',
      ),
    );
  }

  /// Queries airports within a viewport, nearest to the camera centre first.
  Future<List<MapPoint>> queryAirports({
    double? minLat,
    double? maxLat,
    double? minLon,
    double? maxLon,
    double centerLat = 0,
    double centerLon = 0,
    int limit = 400,
  }) async {
    final db = _db;
    if (db == null) return [];

    final query = db.select(db.airports);
    if (minLat != null) {
      query.where((t) => t.latitude.isBiggerOrEqualValue(minLat));
    }
    if (maxLat != null) {
      query.where((t) => t.latitude.isSmallerOrEqualValue(maxLat));
    }
    if (minLon != null) {
      query.where((t) => t.longitude.isBiggerOrEqualValue(minLon));
    }
    if (maxLon != null) {
      query.where((t) => t.longitude.isSmallerOrEqualValue(maxLon));
    }
    query.orderBy([(_) => _distanceOrder(centerLat, centerLon)]);
    query.limit(limit);

    final rows = await query.get();
    return rows.map((r) {
      final elev = r.elevationFt;
      return MapPoint(
        category: NavPointCategory.airport,
        ident: r.icao,
        name: r.name.isEmpty ? r.icao : r.name,
        latitude: r.latitude,
        longitude: r.longitude,
        elevationFt: elev?.toInt(),
      );
    }).toList();
  }

  /// Searches airports, navaids and waypoints by ident or name (SQLite LIKE,
  /// case-insensitive for ASCII). Returns a merged, ident-prefixed result set
  /// across all three tables.
  Future<List<MapPoint>> searchAll(String query, {int limit = 50}) async {
    final db = _db;
    if (db == null) return [];
    final q = query.trim();
    if (q.length < 2) return [];
    final pattern = '%${q.replaceAll("'", "''")}%';

    final result = <MapPoint>[];

    // Airports — match ICAO or name.
    final apQuery = db.select(db.airports)
      ..where((t) => t.icao.like(pattern) | t.name.like(pattern))
      ..limit(limit);
    for (final r in await apQuery.get()) {
      result.add(
        MapPoint(
          category: NavPointCategory.airport,
          ident: r.icao,
          name: r.name.isEmpty ? r.icao : r.name,
          latitude: r.latitude,
          longitude: r.longitude,
          elevationFt: r.elevationFt?.toInt(),
        ),
      );
    }

    // Navaids — VOR family / NDB / ILS family / markers.
    final navQuery = db.select(db.navaids)
      ..where((t) => t.ident.like(pattern) | t.name.like(pattern))
      ..limit(limit);
    for (final r in await navQuery.get()) {
      final cat = _categoryFromType(r.type);
      if (cat == null) continue;
      result.add(
        MapPoint(
          category: cat,
          ident: r.ident,
          name: r.name ?? '',
          latitude: r.latitude,
          longitude: r.longitude,
          frequency: _formatFrequency(r.type, r.frequencyKhz),
        ),
      );
    }

    // Waypoints.
    final fixQuery = db.select(db.fixes)
      ..where((t) => t.ident.like(pattern))
      ..limit(limit);
    for (final r in await fixQuery.get()) {
      result.add(
        MapPoint(
          category: NavPointCategory.waypoint,
          ident: r.ident,
          name: r.ident,
          latitude: r.latitude,
          longitude: r.longitude,
        ),
      );
    }

    return result;
  }

  /// Queries navaids within a viewport, nearest to the camera centre first.
  /// [types] optionally restricts which navaid type strings are returned.
  Future<List<MapPoint>> queryNavaids({
    double? minLat,
    double? maxLat,
    double? minLon,
    double? maxLon,
    double centerLat = 0,
    double centerLon = 0,
    int limit = 800,
    List<String>? types,
  }) async {
    final db = _db;
    if (db == null) return [];

    final query = db.select(db.navaids);
    if (minLat != null) {
      query.where((t) => t.latitude.isBiggerOrEqualValue(minLat));
    }
    if (maxLat != null) {
      query.where((t) => t.latitude.isSmallerOrEqualValue(maxLat));
    }
    if (minLon != null) {
      query.where((t) => t.longitude.isBiggerOrEqualValue(minLon));
    }
    if (maxLon != null) {
      query.where((t) => t.longitude.isSmallerOrEqualValue(maxLon));
    }
    if (types != null) {
      query.where((t) => t.type.isIn(types));
    }
    query.orderBy([(_) => _distanceOrder(centerLat, centerLon)]);
    query.limit(limit);

    final rows = await query.get();
    final result = <MapPoint>[];
    for (final r in rows) {
      final cat = _categoryFromType(r.type);
      if (cat == null) continue;
      result.add(
        MapPoint(
          category: cat,
          ident: r.ident,
          name: r.name ?? '',
          latitude: r.latitude,
          longitude: r.longitude,
          frequency: _formatFrequency(r.type, r.frequencyKhz),
          elevationFt: r.elevationFt?.toInt(),
        ),
      );
    }
    return result;
  }

  /// Queries waypoints/fixes within a viewport, nearest first.
  Future<List<MapPoint>> queryFixes({
    double? minLat,
    double? maxLat,
    double? minLon,
    double? maxLon,
    double centerLat = 0,
    double centerLon = 0,
    int limit = 800,
  }) async {
    final db = _db;
    if (db == null) return [];

    final query = db.select(db.fixes);
    if (minLat != null) {
      query.where((t) => t.latitude.isBiggerOrEqualValue(minLat));
    }
    if (maxLat != null) {
      query.where((t) => t.latitude.isSmallerOrEqualValue(maxLat));
    }
    if (minLon != null) {
      query.where((t) => t.longitude.isBiggerOrEqualValue(minLon));
    }
    if (maxLon != null) {
      query.where((t) => t.longitude.isSmallerOrEqualValue(maxLon));
    }
    query.orderBy([(_) => _distanceOrder(centerLat, centerLon)]);
    query.limit(limit);

    final rows = await query.get();
    return rows
        .map(
          (r) => MapPoint(
            category: NavPointCategory.waypoint,
            ident: r.ident,
            name: r.ident,
            latitude: r.latitude,
            longitude: r.longitude,
          ),
        )
        .toList();
  }

  /// Fetches LNM-style airport details (airport row + its runways) for the
  /// inspector drawer. Returns `null` when the airport is unknown or no
  /// database is open.
  Future<AirportDetails?> queryAirportDetails(String icao) async {
    final db = _db;
    if (db == null) return null;

    final airport = await (db.select(
      db.airports,
    )..where((t) => t.icao.equals(icao))).getSingleOrNull();
    if (airport == null) return null;

    final runwayRows =
        await (db.select(db.runways)
              ..where((t) => t.airportIcao.equals(icao))
              ..orderBy([(t) => OrderingTerm.asc(t.ident)]))
            .get();

    final frequencyRows =
        await (db.select(db.frequencies)
              ..where((t) => t.airportIcao.equals(icao))
              ..orderBy([
                (t) => OrderingTerm.asc(t.type),
                (t) => OrderingTerm.asc(t.frequencyKhz),
              ]))
            .get();

    final runwayStrips = groupRunwayStrips([
      for (final r in runwayRows)
        RunwayDetails(
          ident: r.ident,
          headingDeg: r.headingDeg,
          lengthFt: r.lengthFt,
          widthFt: r.widthFt,
          surface: r.surface,
          stripIndex: r.stripIndex,
        ),
    ]);
    RunwayDetails? longest;
    for (final strip in runwayStrips) {
      final candidate = strip.first;
      if (longest == null || candidate.lengthFt > longest.lengthFt) {
        longest = candidate;
      }
    }

    return AirportDetails(
      icao: airport.icao,
      iata: airport.iata,
      name: airport.name,
      city: airport.city,
      country: airport.country,
      latitude: airport.latitude,
      longitude: airport.longitude,
      elevationFt: airport.elevationFt,
      magvarDeg: airport.magvarDeg,
      type: airport.type,
      source: airport.source,
      runwayStripCount: runwayStrips.length,
      longestRunway: longest,
      runways: [for (final strip in runwayStrips) ...strip],
      frequencies: [
        for (final f in frequencyRows)
          FrequencyDetails(
            type: f.type,
            frequencyKhz: f.frequencyKhz,
            description: f.description,
          ),
      ],
    );
  }

  /// Opens the database (WITHOUT clearing) and returns the per-table row
  /// counts. Used by the splash screen's startup scan — `null`/empty counts
  /// mean no navdata has been imported yet.
  Future<Map<String, int>> readRowCounts() async {
    await _openDb();
    return getRowCounts();
  }

  /// Reads the AIRAC cycle (e.g. `'2608'`) from an X-Plane install's
  /// `cycle_info.txt` (Custom Data first, then the default data folder).
  /// Returns `null` when missing or unparseable (e.g. stock install).
  Future<String?> readAiracCycle(String installPath) async {
    final candidates = [
      p.join(installPath, 'Custom Data', 'cycle_info.txt'),
      p.join(installPath, 'Resources', 'default data', 'cycle_info.txt'),
    ];
    for (final path in candidates) {
      final file = File(path);
      if (!await file.exists()) continue;
      try {
        final text = await file.readAsString();
        // Navigraph style: 'AIRAC cycle    : 2608'. Also tolerate
        // 'CYCLE 2609' one-liners from other vendors.
        final match = RegExp(
          r'AIRAC\s+cycle\s*[:\s]*(\d{4})',
          caseSensitive: false,
        ).firstMatch(text);
        if (match != null) return match.group(1);
      } on Exception catch (_) {
        // Unreadable file — treat as no cycle info.
      }
    }
    return null;
  }

  /// Returns the total row counts per table for status display.
  Future<Map<String, int>> getRowCounts() async {
    final db = _db;
    if (db == null) return {};

    final airportCount = await db.airports.count().getSingle();
    final navaidCount = await db.navaids.count().getSingle();
    final fixCount = await db.fixes.count().getSingle();
    final airwayCount = await db.airways.count().getSingle();

    return {
      'airports': airportCount,
      'navaids': navaidCount,
      'fixes': fixCount,
      'airways': airwayCount,
    };
  }

  void close() {
    _db?.close();
    _db = null;
  }

  static NavPointCategory? _categoryFromType(String type) {
    switch (type) {
      case 'VOR':
        return NavPointCategory.vor;
      case 'VOR/DME':
        return NavPointCategory.vordme;
      case 'VORTAC':
        return NavPointCategory.vortac;
      case 'TACAN':
        return NavPointCategory.tacan;
      case 'DME':
        return NavPointCategory.dme;
      case 'NDB':
        return NavPointCategory.ndb;
      case 'ILS':
      case 'LOC':
      case 'GLS':
        return NavPointCategory.ils;
      case 'GS':
        return NavPointCategory.gs;
      case 'OM':
      case 'MM':
      case 'IM':
        return NavPointCategory.marker;
      default:
        return null;
    }
  }

  /// X-Plane stores VOR/ILS family frequency as MHz×100 (e.g. 11630 =
  /// 116.30 MHz) and NDB as kHz. Format accordingly for display.
  static String? _formatFrequency(String type, double raw) {
    if (raw <= 0) return null;
    switch (type) {
      case 'NDB':
        return '${raw.toStringAsFixed(0)} kHz';
      case 'VOR':
      case 'VOR/DME':
      case 'VORTAC':
      case 'TACAN':
      case 'DME':
      case 'ILS':
      case 'LOC':
      case 'GS':
      case 'GLS':
        return '${(raw / 100).toStringAsFixed(2)} MHz';
      default:
        return raw.toStringAsFixed(0);
    }
  }
}


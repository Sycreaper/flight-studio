import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/navdata/navdata_types.dart';
import '../../core/parsing/earth_nav_parser.dart';
import '../background_tasks.dart';
import '../settings/simulator_install.dart';
import 'importer.dart';

/// App-wide navdata service. Owns the [NavdataImporter], runs imports in the
/// background (with progress reported through [BackgroundTaskManager]), and
/// serves map-marker queries.
///
/// The map listens to this [ChangeNotifier]: after a successful import the
/// marker list becomes available and the map re-queries.
class NavdataService extends ChangeNotifier {
  NavdataService._();

  static final NavdataService instance = NavdataService._();

  final NavdataImporter _importer = NavdataImporter();

  Map<String, int> _lastRowCounts = const {};

  Map<String, int> get rowCounts => _lastRowCounts;

  /// `true` once a database exists with at least one row imported.
  bool get isLoaded => _lastRowCounts.values.any((c) => c > 0);

  /// Imports navdata for the **first supported** simulator in [simulators].
  ///
  /// Only X-Plane 12 is supported today. Four files are read:
  /// 1. `Custom Data/earth_nav.dat` — navaids
  /// 2. `Custom Data/earth_fix.dat` — waypoints
  /// 3. `Custom Data/earth_awy.dat` — airways
  /// 4. `Global Scenery/Global Airports/Earth nav data/apt.dat` — airports
  ///
  /// Overall progress = weighted average of the per-file progresses, weighted
  /// by approximate file size (apt.dat dominates at ~363 MB).
  Future<void> importFromSimulators(List<SimulatorInstall> simulators) async {
    final supported = simulators.where((s) => s.type.isSupported).toList();
    if (supported.isEmpty) return;

    final sim = supported.first;
    final task = BackgroundTaskManager.instance.startTask(
      'Importing navdata — ${sim.name ?? sim.type.name}',
    );

    try {
      final db = await _importer.openAndClear();
      final dataDir = await _importer.resolveDataDir(sim.path);
      final dataPath = '${sim.path.replaceAll('\\', '/')}/$dataDir';

      // Progress weights (approx. file sizes): nav 3.7M, fix 15M, awy 7.6M,
      // apt 363M → normalized.
      const wNav = 0.008;
      const wFix = 0.032;
      const wAwy = 0.016;
      const wApt = 0.944;

      void progressFor(
        double base,
        double weight,
        int current,
        int total,
        String msg,
      ) {
        final fileProgress = total > 0 ? current / total : 0.0;
        BackgroundTaskManager.instance.updateTask(
          task,
          (base + fileProgress * weight).clamp(0.0, 0.99),
          label: msg,
        );
      }

      var navaids = 0;
      var fixes = 0;
      var airways = 0;
      var airports = 0;

      final navFile = File('$dataPath/earth_nav.dat');
      if (await navFile.exists()) {
        navaids = await importEarthNav(
          navFile,
          db,
          onProgress: (c, t, m) => progressFor(0.0, wNav, c, t, m),
        );
      }

      final fixFile = File('$dataPath/earth_fix.dat');
      if (await fixFile.exists()) {
        fixes = await importEarthFix(
          fixFile,
          db,
          onProgress: (c, t, m) => progressFor(wNav, wFix, c, t, m),
        );
      }

      final awyFile = File('$dataPath/earth_awy.dat');
      if (await awyFile.exists()) {
        airways = await importEarthAwy(
          awyFile,
          db,
          onProgress: (c, t, m) => progressFor(wNav + wFix, wAwy, c, t, m),
        );
      }

      // Airports — global first, then custom scenery packs (override global).
      final aptFiles = await _importer.discoverAptFiles(sim.path);
      if (aptFiles.isNotEmpty) {
        airports = await _importer.importAptFiles(
          aptFiles,
          db,
          onProgress: (c, t, m) =>
              progressFor(wNav + wFix + wAwy, wApt, c, t, m),
        );
      }

      _lastRowCounts = await _importer.getRowCounts();
      BackgroundTaskManager.instance.completeTask(task);
      debugPrint(
        'Navdata import done: navaids=$navaids fixes=$fixes '
        'airways=$airways airports=$airports',
      );
      notifyListeners();
    } on Exception catch (e) {
      BackgroundTaskManager.instance.failTask(task, e.toString());
    } on Error catch (e) {
      BackgroundTaskManager.instance.failTask(task, e.toString());
    }
  }

  /// Full-text search across airports, navaids and waypoints.
  Future<List<NavPoint>> searchAll(String query, {int limit = 50}) async {
    final points = await _importer.searchAll(query, limit: limit);
    return points.map(_toNavPoint).toList();
  }

  /// Queries airports within a viewport, nearest to centre first.
  Future<List<NavPoint>> queryAirports({
    double? minLat,
    double? maxLat,
    double? minLon,
    double? maxLon,
    double centerLat = 0,
    double centerLon = 0,
    int limit = 400,
  }) async {
    final points = await _importer.queryAirports(
      minLat: minLat,
      maxLat: maxLat,
      minLon: minLon,
      maxLon: maxLon,
      centerLat: centerLat,
      centerLon: centerLon,
      limit: limit,
    );
    return points.map(_toNavPoint).toList();
  }

  /// Queries navaids within a viewport, nearest to centre first. [types]
  /// filters which navaid type strings to include.
  Future<List<NavPoint>> queryNavaids({
    double? minLat,
    double? maxLat,
    double? minLon,
    double? maxLon,
    double centerLat = 0,
    double centerLon = 0,
    int limit = 800,
    List<String>? types,
  }) async {
    final points = await _importer.queryNavaids(
      minLat: minLat,
      maxLat: maxLat,
      minLon: minLon,
      maxLon: maxLon,
      centerLat: centerLat,
      centerLon: centerLon,
      limit: limit,
      types: types,
    );
    return points.map(_toNavPoint).toList();
  }

  /// Queries waypoints/fixes within a viewport, nearest to centre first.
  Future<List<NavPoint>> queryFixes({
    double? minLat,
    double? maxLat,
    double? minLon,
    double? maxLon,
    double centerLat = 0,
    double centerLon = 0,
    int limit = 800,
  }) async {
    final points = await _importer.queryFixes(
      minLat: minLat,
      maxLat: maxLat,
      minLon: minLon,
      maxLon: maxLon,
      centerLat: centerLat,
      centerLon: centerLon,
      limit: limit,
    );
    return points.map(_toNavPoint).toList();
  }

  static NavPoint _toNavPoint(MapPoint p) => NavPoint(
    category: p.category,
    ident: p.ident,
    name: p.name,
    latitude: p.latitude,
    longitude: p.longitude,
    frequency: p.frequency,
    elevationFt: p.elevationFt,
  );
}

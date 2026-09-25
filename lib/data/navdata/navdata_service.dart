import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/navdata/navdata_types.dart';
import '../../l10n/import_messages.dart';
import '../background_tasks.dart';
import '../settings/settings_keys.dart';
import '../settings/simulator_install.dart';
import 'airport_details.dart';
import 'importer.dart';
import 'navdata_provider.dart';
import 'ourairports_enricher.dart';

/// App-wide navdata service. Owns the [NavdataImporter] and the open
/// database, runs imports through the registered [NavdataProvider] (progress
/// reported via [BackgroundTaskManager]), and serves map-marker queries.
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

  /// Startup scan (splash screen): opens the existing database without
  /// importing and reports whether any navdata is present. Refreshes
  /// [rowCounts] so the status bar reflects it immediately. Returns `false`
  /// on any failure (fresh install / test environment).
  Future<bool> scanExistingData() async {
    // The scan opens the app-support DB via path_provider — unavailable and
    // non-completing under `flutter test` (same gate as SystemStatsService).
    if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    try {
      _lastRowCounts = await _importer.readRowCounts();
      notifyListeners();
      return _lastRowCounts.values.any((c) => c > 0);
    } on Exception catch (_) {
      return false;
    } on Error catch (_) {
      return false;
    }
  }

  /// Imports navdata for the **first** simulator in [simulators] that has a
  /// registered [NavdataProvider] (capability-based — no type switch here).
  ///
  /// Providers report normalized progress, which is forwarded to the
  /// status-bar background task.
  Future<void> importFromSimulators(List<SimulatorInstall> simulators) async {
    for (final sim in simulators) {
      final provider =
      NavdataProviderRegistry.instance.forInstall(sim);
      if (provider == null) continue;

      final task = BackgroundTaskManager.instance.startTask(
        ImportMessages.importingNavdata(sim.name ?? sim.type.name),
      );

      try {
        final db = await _importer.openAndClear();
        await provider.importInto(
          db,
          _importer,
          sim,
          onProgress: (progress, message) =>
              BackgroundTaskManager.instance.updateTask(
                task,
                progress.clamp(0.0, 0.99),
                label: message,
              ),
        );
        _lastRowCounts = await _importer.getRowCounts();
        // Enrich iata/city/country from OurAirports (cached, best-effort) —
        // apt.dat carries none of these fields.
        final openDb = _importer.database;
        if (openDb != null) {
          await OurAirportsEnricher.instance.enrich(
            openDb,
            supportDir: getApplicationSupportDirectory,
            onMessage: (message) =>
                BackgroundTaskManager.instance.updateTask(
                  task,
                  0.99,
                  label: message,
                ),
          );
        }
        BackgroundTaskManager.instance.completeTask(task);
        await _recordScanTime();
        debugPrint('Navdata import done via ${provider.id}: $_lastRowCounts');
        notifyListeners();
      } on Exception catch (e) {
        BackgroundTaskManager.instance.failTask(task, e.toString());
      } on Error catch (e) {
        BackgroundTaskManager.instance.failTask(task, e.toString());
      }
      return;
    }
  }

  /// Persists the scan timestamp (drives the splash "last scan > N days"
  /// thresholds). Fire-and-forget — a failed write only means the next
  /// launch considers the data older than it is.
  Future<void> _recordScanTime() async {
    try {
      await SharedPreferencesAsync().setString(
        SettingsKeys.navdataLastScanAt,
        DateTime.now().toUtc().toIso8601String(),
      );
    } on Exception catch (_) {
      // Best-effort.
    }
  }

  /// LNM-style airport details (incl. runways) for the inspector drawer.
  /// Returns `null` when unknown or no database is open (e.g. in tests).
  Future<AirportDetails?> queryAirportDetails(String icao) =>
      _importer.queryAirportDetails(icao);

  /// AIRAC cycle of an install's navdata (from `cycle_info.txt`), e.g.
  /// `'2608'` — `null` when missing/unreadable. Never throws.
  Future<String?> readAiracCycle(SimulatorInstall install) async {
    try {
      return await _importer.readAiracCycle(install.path);
    } on Exception catch (_) {
      return null;
    } on Error catch (_) {
      return null;
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

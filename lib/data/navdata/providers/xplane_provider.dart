import 'dart:io';

import '../../../core/parsing/earth_nav_parser.dart';
import '../../db/database.dart';
import '../../settings/simulator_install.dart';
import '../importer.dart';
import '../navdata_provider.dart';

/// Imports navigation data from an X-Plane 12 install:
///
/// 1. `Custom Data/earth_nav.dat` — navaids
/// 2. `Custom Data/earth_fix.dat` — waypoints
/// 3. `Custom Data/earth_awy.dat` — airways
/// 4. `Global Scenery/.../apt.dat` (+ custom scenery packs) — airports
///
/// Overall progress is a weighted average of the per-file progresses,
/// weighted by approximate file size (apt.dat dominates at ~363 MB).
class XPlaneNavdataProvider extends NavdataProvider {
  @override
  String get id => 'xplane12';

  @override
  String get displayName => 'X-Plane 12';

  @override
  bool canImport(SimulatorInstall install) =>
      install.type == SimulatorType.xplane12;

  @override
  Future<void> importInto(
    NavdataDatabase db,
    NavdataImporter importer,
    SimulatorInstall install, {
    void Function(double progress, String message)? onProgress,
  }) async {
    final dataDir = await importer.resolveDataDir(install.path);
    final dataPath = '${install.path.replaceAll('\\', '/')}/$dataDir';

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
      onProgress?.call((base + fileProgress * weight).clamp(0.0, 0.99), msg);
    }

    final navFile = File('$dataPath/earth_nav.dat');
    if (await navFile.exists()) {
      await importEarthNav(
        navFile,
        db,
        onProgress: (c, t, m) => progressFor(0.0, wNav, c, t, m),
      );
    }

    final fixFile = File('$dataPath/earth_fix.dat');
    if (await fixFile.exists()) {
      await importEarthFix(
        fixFile,
        db,
        onProgress: (c, t, m) => progressFor(wNav, wFix, c, t, m),
      );
    }

    final awyFile = File('$dataPath/earth_awy.dat');
    if (await awyFile.exists()) {
      await importEarthAwy(
        awyFile,
        db,
        onProgress: (c, t, m) => progressFor(wNav + wFix, wAwy, c, t, m),
      );
    }

    // Airports — global first, then custom scenery packs (override global).
    final aptFiles = await importer.discoverAptFiles(install.path);
    if (aptFiles.isNotEmpty) {
      await importer.importAptFiles(
        aptFiles,
        db,
        onProgress: (c, t, m) => progressFor(wNav + wFix + wAwy, wApt, c, t, m),
      );
    }
  }
}

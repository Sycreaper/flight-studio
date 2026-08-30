// Smoke test against the REAL X-Plane 12 installation on this machine.
// Skips automatically when the install path doesn't exist, so CI elsewhere
// still passes.
//
// Run: flutter test test/nav_parser_real_test.dart

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flight_studio/core/parsing/apt_dat_parser.dart';
import 'package:flight_studio/core/parsing/earth_nav_parser.dart';
import 'package:flight_studio/data/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

const _xplanePath = r'D:\Resources\Softwares\X-Plane12';
const _aptPath =
    r'D:\Resources\Softwares\X-Plane12\Global Scenery\Global Airports\Earth nav data\apt.dat';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dataDir = Directory('$_xplanePath/Custom Data');
  final hasRealData = dataDir.existsSync();

  test('real earth_nav.dat import smoke', () async {
    if (!hasRealData) return; // Skip on machines without the install.

    final db = NavdataDatabase(NativeDatabase.memory());
    addTearDown(() => db.close());

    final file = File('${dataDir.path}/earth_nav.dat');
    final count = await importEarthNav(file, db);

    // Real file has ~22k data rows; after skipping paired DME (type 12) and
    // SBAS points, ~17.6k unique navaids remain.
    expect(count, greaterThan(15000), reason: 'Should import ~17.6k navaids');

    final byType = <String, int>{};
    for (final row in await db.select(db.navaids).get()) {
      byType[row.type] = (byType[row.type] ?? 0) + 1;
    }
    // Core types must all be present with realistic counts. Real-world
    // distribution: VOR/DME 2991, TACAN 434, VORTAC 473, pure VOR only 120
    // (most VORs in modern datasets carry DME).
    expect(byType['VOR'] ?? 0, greaterThan(50));
    expect(byType['VOR/DME'] ?? 0, greaterThan(1000));
    expect(byType['VORTAC'] ?? 0, greaterThan(100));
    expect(byType['TACAN'] ?? 0, greaterThan(100));
    expect(byType['NDB'] ?? 0, greaterThan(500));
    expect(byType['ILS'] ?? 0, greaterThan(1000));
    expect(byType['LOC'] ?? 0, greaterThan(50));
    expect(byType['GS'] ?? 0, greaterThan(50));
    expect(byType['DME'] ?? 0, greaterThan(100));
    expect(byType['OM'] ?? 0, greaterThan(50));
    expect(byType['MM'] ?? 0, greaterThan(50));
    expect(byType['IM'] ?? 0, greaterThan(50));
    expect(byType['GLS'] ?? 0, greaterThan(10));
  }, timeout: const Timeout(Duration(minutes: 5)));

  test(
    'real earth_fix.dat import smoke',
    () async {
      if (!hasRealData) return;

      final db = NavdataDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      final file = File('${dataDir.path}/earth_fix.dat');
      final count = await importEarthFix(file, db);

      // Real file has ~250k fixes.
      expect(count, greaterThan(200000));
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );

  test('real earth_awy.dat import smoke', () async {
    if (!hasRealData) return;

    final db = NavdataDatabase(NativeDatabase.memory());
    addTearDown(() => db.close());

    final file = File('${dataDir.path}/earth_awy.dat');
    final count = await importEarthAwy(file, db);

    // Real file has ~110k segments.
    expect(count, greaterThan(100000));

    final sample = await (db.select(db.airways)..limit(5)).get();
    expect(sample, isNotEmpty);
    for (final seg in sample) {
      expect(seg.name, isNotEmpty);
      expect(seg.startIdent, isNotEmpty);
      expect(seg.endIdent, isNotEmpty);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  test(
    'real apt.dat import smoke (363 MB global airports)',
    () async {
      final file = File(_aptPath);
      if (!file.existsSync()) return; // Skip on machines without the install.

      final db = NavdataDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      final count = await importAptDat(file, db);

      // Global Airports ships ~40k airports.
      expect(count, greaterThan(30000));

      final airports = await db.select(db.airports).get();
      final byType = <String, int>{};
      for (final a in airports) {
        byType[a.type] = (byType[a.type] ?? 0) + 1;
      }
      expect(byType['airport'] ?? 0, greaterThan(20000));
      expect(byType['heliport'] ?? 0, greaterThan(20));

      // KSEA must exist at the right spot (longest-runway midpoint).
      final ksea = airports.where((a) => a.icao == 'KSEA').firstOrNull;
      expect(ksea, isNotNull, reason: 'KSEA present in global airports');
      expect(ksea!.latitude, closeTo(47.45, 0.05));
      expect(ksea.longitude, closeTo(-122.31, 0.05));

      // Runways present and long for KSEA.
      final rwys = await (db.select(
        db.runways,
      )..where((r) => r.airportIcao.equals('KSEA'))).get();
      expect(rwys, isNotEmpty);
      expect(rwys.first.lengthFt, greaterThan(8000));
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

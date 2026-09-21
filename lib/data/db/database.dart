import 'package:drift/drift.dart';

import 'tables/airports.dart';
import 'tables/airways.dart';
import 'tables/fixes.dart';
import 'tables/frequencies.dart';
import 'tables/navaids.dart';
import 'tables/runways.dart';

part 'database.g.dart';

/// The main Flight Studio navdata database. Populated by the X-Plane navdata
/// importer (Phase 2) from `apt.dat`, `earth_nav.dat`, `earth_fix.dat` and
/// `awy.dat`.
///
/// Query access is via the repository layer (`lib/data/repositories/`); widgets
/// should never import this class directly.
@DriftDatabase(
    tables: [Airports, Runways, Frequencies, Navaids, Fixes, Airways])
class NavdataDatabase extends _$NavdataDatabase {
  NavdataDatabase(super.connection);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // v2: ATC frequency table (parsed from apt.dat rows 50–56).
          if (from < 2) {
            await m.createTable(frequencies);
          }
          // v3: runways stored as PAIRS — both ends, tagged with their
          // physical strip so the inspector can show them as `16L/34R`.
          if (from < 3) {
            await m.addColumn(runways, runways.stripIndex);
          }
          // v4: airport magnetic declination (apt.dat row 1 field 3).
          if (from < 4) {
            await m.addColumn(airports, airports.magvarDeg);
          }
        },
      );
}

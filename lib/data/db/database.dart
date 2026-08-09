import 'package:drift/drift.dart';

import 'tables/airports.dart';
import 'tables/airways.dart';
import 'tables/fixes.dart';
import 'tables/navaids.dart';
import 'tables/runways.dart';

part 'database.g.dart';

/// The main Flight Studio navdata database. Populated by the X-Plane navdata
/// importer (Phase 2) from `apt.dat`, `earth_nav.dat`, `earth_fix.dat` and
/// `awy.dat`.
///
/// Query access is via the repository layer (`lib/data/repositories/`); widgets
/// should never import this class directly.
@DriftDatabase(tables: [Airports, Runways, Navaids, Fixes, Airways])
class NavdataDatabase extends _$NavdataDatabase {
  NavdataDatabase(super.connection);

  @override
  int get schemaVersion => 1;
}

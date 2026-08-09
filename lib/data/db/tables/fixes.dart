import 'package:drift/drift.dart';

/// X-Plane `earth_fix.dat` — named intersection / waypoint.
class Fixes extends Table {
  TextColumn get ident => text()(); // e.g. 'ETO', 'GWD'
  RealColumn get latitude => real()();

  RealColumn get longitude => real()();

  TextColumn get description => text().nullable()();

  TextColumn get source => text()();

  @override
  Set<Column<Object>> get primaryKey => {ident, latitude, longitude};
}

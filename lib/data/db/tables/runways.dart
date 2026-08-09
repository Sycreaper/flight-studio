import 'package:drift/drift.dart';

/// X-Plane `apt.dat` row 100 — runway definition.
class Runways extends Table {
  TextColumn get airportIcao => text()();

  TextColumn get ident => text()(); // e.g. '16L', '34R'
  RealColumn get latitude => real()();

  RealColumn get longitude => real()();

  RealColumn get lengthFt => real()();

  RealColumn get widthFt => real().nullable()();

  RealColumn get headingDeg => real()(); // true heading
  TextColumn get surface =>
      text().nullable()(); // 'asphalt' | 'concrete' | 'grass' | ...
  TextColumn get edgeLights =>
      text().nullable()(); // 'none' | 'edge' | 'center'

  @override
  Set<Column<Object>> get primaryKey => {airportIcao, ident};
}

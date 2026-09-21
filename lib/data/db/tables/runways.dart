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

  /// Identifies the physical strip both ends of a runway pair belong to
  /// (0, 1, 2... per airport, from apt.dat row 100/101 order). `null` in
  /// databases imported before v3.
  IntColumn get stripIndex => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {airportIcao, ident};
}

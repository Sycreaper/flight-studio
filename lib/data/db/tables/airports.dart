import 'package:drift/drift.dart';

/// X-Plane `apt.dat` row 1 — airport / heliport / seaplane base.
class Airports extends Table {
  TextColumn get icao => text()(); // e.g. 'KSEA'
  TextColumn get iata => text().nullable()(); // e.g. 'SEA'
  TextColumn get name => text()();

  TextColumn get city => text().nullable()();

  TextColumn get country => text().nullable()();

  RealColumn get latitude => real()();

  RealColumn get longitude => real()();

  RealColumn get elevationFt => real().nullable()();

  /// Magnetic declination (apt.dat row 1 field 3 — deprecated by X-Plane but
  /// still populated by many datasets; `null` when absent).
  RealColumn get magvarDeg => real().nullable()();

  TextColumn get type => text()(); // 'airport' | 'heliport' | 'seaplane'
  TextColumn get source => text()(); // 'xplane' | 'ourairports' | 'navigraph'

  @override
  Set<Column<Object>> get primaryKey => {icao};
}

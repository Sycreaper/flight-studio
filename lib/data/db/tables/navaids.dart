import 'package:drift/drift.dart';

/// X-Plane `earth_nav.dat` — VOR, NDB, ILS, DME, etc.
class Navaids extends Table {
  TextColumn get ident => text()(); // e.g. 'SEA', 'IM'
  TextColumn get name => text().nullable()();

  TextColumn get type => text()(); // 'VOR' | 'NDB' | 'ILS' | 'DME' | ...
  RealColumn get frequencyKhz => real()(); // NDB: kHz; others: MHz*1000
  RealColumn get latitude => real()();

  RealColumn get longitude => real()();

  RealColumn get elevationFt => real().nullable()();

  RealColumn get dmeRangeNm => real().nullable()();

  TextColumn get source => text()();

  @override
  Set<Column<Object>> get primaryKey => {ident, type, latitude, longitude};
}

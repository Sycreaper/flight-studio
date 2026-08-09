import 'package:drift/drift.dart';

/// X-Plane `awy.dat` — airway segments (one row per edge in the airway graph).
class Airways extends Table {
  TextColumn get name => text()(); // e.g. 'V609', 'J547', 'NCA1'
  TextColumn get startIdent => text()(); // fix or navaid ident
  TextColumn get endIdent => text()();

  TextColumn get startType => text()(); // 'fix' | 'navaid'
  TextColumn get endType => text()();

  RealColumn get baseFlightLevel => real().nullable()();

  RealColumn get topFlightLevel => real().nullable()();

  TextColumn get direction =>
      text().nullable()(); // 'both' | 'forward' | 'backward'
  TextColumn get source => text()();

  @override
  Set<Column<Object>> get primaryKey => {name, startIdent, endIdent};
}

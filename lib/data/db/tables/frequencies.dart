import 'package:drift/drift.dart';

/// X-Plane `apt.dat` rows 50–56 — airport ATC frequencies:
///
/// - 50 ATIS, 51 CTAF (unicom), 52 GND, 53 TWR, 54 CLD, 55 APP, 56 DEP.
/// Frequencies are stored in kHz (apt.dat convention, e.g. 119500 → 119.5).
/// A type may appear multiple times per airport (e.g. parallel GND freqs),
/// so there is no composite primary key — rows are keyed by rowid and
/// indexed by airport for the inspector lookup.
@TableIndex(name: 'idx_frequencies_airport', columns: {#airportIcao})
class Frequencies extends Table {
  TextColumn get airportIcao => text()();

  /// `'ATIS' | 'CTAF' | 'GND' | 'TWR' | 'CLD' | 'APP' | 'DEP'`.
  TextColumn get type => text()();

  IntColumn get frequencyKhz => integer()();

  /// Free-text station name from the apt.dat row (often empty).
  TextColumn get description => text().nullable()();
}

import 'flight_record.dart';

/// Repository for saved flight records.
///
/// Backed by an in-memory list for now; a drift-backed implementation replaces
/// this once persistence is wired up in phase 1+. Consumers depend on this
/// abstraction so the swap is transparent.
class FlightRepository {
  FlightRepository() : _records = const [];

  List<FlightRecord> _records;

  List<FlightRecord> all() => List.unmodifiable(_records);

  /// Filters records by a free-text query against route, aircraft and airline.
  List<FlightRecord> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all();
    return _records.where((r) {
      return r.route.toLowerCase().contains(q) ||
          r.aircraftName.toLowerCase().contains(q) ||
          r.airlineName.toLowerCase().contains(q) ||
          (r.flightNumber?.toLowerCase().contains(q) ?? false);
    }).toList(growable: false);
  }

  Future<void> add(FlightRecord record) async {
    _records = [..._records, record];
  }

  Future<void> seed(List<FlightRecord> records) async {
    _records = List.unmodifiable(records);
  }
}

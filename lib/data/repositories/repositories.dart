/// A navigational data point with a geographic position. Shared interface for
/// airports, navaids and fixes so the map renderer and search can treat them
/// uniformly.
abstract class NavdataPoint {
  String get ident;

  String get name;

  double get latitude;

  double get longitude;

  String get type; // 'airport' | 'vor' | 'ndb' | 'fix' | ...
}

/// Abstract airport repository. The drift-backed implementation is created in
/// Phase 2 when the X-Plane navdata importer ships.
abstract class AirportRepository {
  /// Finds an airport by its ICAO code (e.g. 'KSEA'). Returns `null` if not
  /// found.
  Future<NavdataPoint?> getByIcao(String icao);

  /// Searches airports by ICAO, IATA or name (case-insensitive, prefix match).
  Future<List<NavdataPoint>> search(String query, {int limit = 20});

  /// Returns all airports within [radiusNm] of the given point.
  Future<List<NavdataPoint>> nearby(
    double lat,
    double lon, {
    double radiusNm = 50,
    int limit = 50,
  });
}

/// Abstract navaid (VOR/NDB/DME) repository.
abstract class NavaidRepository {
  Future<NavdataPoint?> getByIdent(String ident);

  Future<List<NavdataPoint>> search(String query, {int limit = 20});
}

/// Abstract waypoint / intersection repository.
abstract class FixRepository {
  Future<NavdataPoint?> getByIdent(String ident);

  Future<List<NavdataPoint>> search(String query, {int limit = 20});
}

/// Abstract airway repository.
abstract class AirwayRepository {
  /// Returns all segments that make up [name].
  Future<List<AirwaySegment>> getSegments(String name);

  /// Searches airway names by prefix.
  Future<List<String>> searchNames(String query, {int limit = 20});
}

/// One directed edge in the airway graph.
class AirwaySegment {
  const AirwaySegment({
    required this.airwayName,
    required this.startIdent,
    required this.endIdent,
    this.baseFlightLevel,
    this.topFlightLevel,
  });

  final String airwayName;
  final String startIdent;
  final String endIdent;
  final double? baseFlightLevel;
  final double? topFlightLevel;
}

/// A single saved flight record shown in the Recent Flights list.
///
/// This is the lightweight view-model for the welcome screen; richer state
/// (route legs, performance, telemetry history) lives in the planning core.
class FlightRecord {
  FlightRecord({
    required this.id,
    required this.departure,
    required this.arrival,
    required this.aircraftName,
    required this.airlineName,
    this.flightNumber,
    this.cruiseAltitudeFt,
    this.durationMinutes,
    this.createdAt,
    this.aircraftThumbnailPath,
  });

  final String id;
  final String departure;
  final String arrival;
  final String aircraftName;
  final String airlineName;
  final String? flightNumber;
  final int? cruiseAltitudeFt;
  final int? durationMinutes;
  final DateTime? createdAt;
  final String? aircraftThumbnailPath;

  /// Routes: e.g. "KSEA → KSFO".
  String get route => '$departure \u2192 $arrival';
}

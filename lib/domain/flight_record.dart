/// A completed (or planned-but-not-yet-flown) flight record. This is the
/// persistent log entry shown in the welcome screen's "Recent Flights" list
/// and later consumed by the debrief engine (Phase 8).
///
/// Has a stable [id] and [createdAt] timestamp for cloud-sync readiness.
class FlightRecord {
  FlightRecord({
    required this.id,
    this.pilotId,
    this.intentId,
    required this.departure,
    required this.arrival,
    this.aircraftName,
    this.airlineName,
    this.flightNumber,
    this.cruiseAltitudeFt,
    this.durationMinutes,
    this.routeString,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String? pilotId;
  final String? intentId;
  final String departure;
  final String arrival;
  final String? aircraftName;
  final String? airlineName;
  final String? flightNumber;
  final int? cruiseAltitudeFt;
  final int? durationMinutes;
  final String? routeString;
  final DateTime createdAt;

  String get routeLabel => '$departure → $arrival';

  Map<String, dynamic> toJson() => {
    'id': id,
    'pilotId': pilotId,
    'intentId': intentId,
    'departure': departure,
    'arrival': arrival,
    'aircraftName': aircraftName,
    'airlineName': airlineName,
    'flightNumber': flightNumber,
    'cruiseAltitudeFt': cruiseAltitudeFt,
    'durationMinutes': durationMinutes,
    'routeString': routeString,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FlightRecord.fromJson(Map<String, dynamic> json) => FlightRecord(
    id: json['id'] as String,
    pilotId: json['pilotId'] as String?,
    intentId: json['intentId'] as String?,
    departure: json['departure'] as String,
    arrival: json['arrival'] as String,
    aircraftName: json['aircraftName'] as String?,
    airlineName: json['airlineName'] as String?,
    flightNumber: json['flightNumber'] as String?,
    cruiseAltitudeFt: json['cruiseAltitudeFt'] as int?,
    durationMinutes: json['durationMinutes'] as int?,
    routeString: json['routeString'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

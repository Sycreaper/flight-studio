/// The user's planned flight — the "I want to fly from A to B via C at FL350"
/// object. Created before departure, consumed by the route engine, the form UI,
/// the exporter and the AI copilot.
class FlightIntent {
  FlightIntent({
    required this.id,
    required this.pilotId,
    this.aircraftType,
    this.aircraftRegistration,
    this.airline,
    this.flightNumber,
    required this.departureIcao,
    required this.destinationIcao,
    this.alternateIcao,
    this.cruiseFlightLevel,
    this.routeString,
    this.sid,
    this.star,
    this.approach,
    this.costIndex,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String pilotId;
  final String? aircraftType;
  final String? aircraftRegistration;
  final String? airline;
  final String? flightNumber;
  final String departureIcao;
  final String destinationIcao;
  final String? alternateIcao;
  final int? cruiseFlightLevel;
  final String? routeString;
  final String? sid;
  final String? star;
  final String? approach;
  final int? costIndex;
  final DateTime createdAt;

  String get route => '$departureIcao → $destinationIcao';

  Map<String, dynamic> toJson() => {
    'id': id,
    'pilotId': pilotId,
    'aircraftType': aircraftType,
    'aircraftRegistration': aircraftRegistration,
    'airline': airline,
    'flightNumber': flightNumber,
    'departureIcao': departureIcao,
    'destinationIcao': destinationIcao,
    'alternateIcao': alternateIcao,
    'cruiseFlightLevel': cruiseFlightLevel,
    'routeString': routeString,
    'sid': sid,
    'star': star,
    'approach': approach,
    'costIndex': costIndex,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FlightIntent.fromJson(Map<String, dynamic> json) => FlightIntent(
    id: json['id'] as String,
    pilotId: json['pilotId'] as String,
    aircraftType: json['aircraftType'] as String?,
    aircraftRegistration: json['aircraftRegistration'] as String?,
    airline: json['airline'] as String?,
    flightNumber: json['flightNumber'] as String?,
    departureIcao: json['departureIcao'] as String,
    destinationIcao: json['destinationIcao'] as String,
    alternateIcao: json['alternateIcao'] as String?,
    cruiseFlightLevel: json['cruiseFlightLevel'] as int?,
    routeString: json['routeString'] as String?,
    sid: json['sid'] as String?,
    star: json['star'] as String?,
    approach: json['approach'] as String?,
    costIndex: json['costIndex'] as int?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

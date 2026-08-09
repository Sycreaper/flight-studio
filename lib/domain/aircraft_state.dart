/// A real-time telemetry snapshot of the user's aircraft. Produced by the
/// simulator adapter (X-Plane UDP, MSFS SimConnect) at ~10 Hz and consumed by
/// the map, flight-path recorder and AI copilot.
///
/// Immutable value object — each update creates a new instance.
class AircraftState {
  const AircraftState({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.altitudeFt,
    required this.headingDeg,
    required this.speedKt,
    this.verticalSpeedFps = 0,
    this.fuelKg,
    this.onGround = true,
  });

  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double altitudeFt;
  final double headingDeg;
  final double speedKt;
  final double verticalSpeedFps;
  final double? fuelKg;
  final bool onGround;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'altitudeFt': altitudeFt,
    'headingDeg': headingDeg,
    'speedKt': speedKt,
    'verticalSpeedFps': verticalSpeedFps,
    'fuelKg': fuelKg,
    'onGround': onGround,
  };

  factory AircraftState.fromJson(Map<String, dynamic> json) => AircraftState(
    timestamp: DateTime.parse(json['timestamp'] as String),
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    altitudeFt: (json['altitudeFt'] as num).toDouble(),
    headingDeg: (json['headingDeg'] as num).toDouble(),
    speedKt: (json['speedKt'] as num).toDouble(),
    verticalSpeedFps: (json['verticalSpeedFps'] as num?)?.toDouble() ?? 0,
    fuelKg: (json['fuelKg'] as num?)?.toDouble(),
    onGround: json['onGround'] as bool? ?? true,
  );
}

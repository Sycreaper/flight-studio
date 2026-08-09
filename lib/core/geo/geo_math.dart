import 'dart:math' as math;

/// Great-circle (Haversine) distance between two lat/lon points in nautical
/// miles. Uses the mean Earth radius of 3440.065 nm.
double haversineNm(double lat1, double lon1, double lat2, double lon2) {
  const r = 3440.065; // Earth mean radius in nm.
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) *
          math.cos(_toRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

/// Initial great-circle bearing from point 1 to point 2, in degrees [0..360).
double initialBearing(double lat1, double lon1, double lat2, double lon2) {
  final phi1 = _toRad(lat1);
  final phi2 = _toRad(lat2);
  final deltaLambda = _toRad(lon2 - lon1);
  final y = math.sin(deltaLambda) * math.cos(phi2);
  final x =
      math.cos(phi1) * math.sin(phi2) -
      math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);
  return (_toDeg(math.atan2(y, x)) + 360) % 360;
}

/// Destination point given a start, initial bearing and distance (nm).
/// Returns `[lat, lon]`.
List<double> destinationPoint(
  double lat,
  double lon,
  double bearingDeg,
  double distanceNm,
) {
  const r = 3440.065;
  final delta = distanceNm / r;
  final theta = _toRad(bearingDeg);
  final phi1 = _toRad(lat);
  final lambda1 = _toRad(lon);

  final sinPhi2 =
      math.sin(phi1) * math.cos(delta) +
      math.cos(phi1) * math.sin(delta) * math.cos(theta);
  final phi2 = math.asin(sinPhi2);
  final y = math.sin(theta) * math.sin(delta) * math.cos(phi1);
  final x = math.cos(delta) - math.sin(phi1) * sinPhi2;
  final lambda2 = lambda1 + math.atan2(y, x);

  return [_toDeg(phi2), ((_toDeg(lambda2) + 540) % 360) - 180];
}

/// Formats a latitude value as `N42°21'28.8"` (DMS with hemisphere prefix).
String formatLatDMS(double lat) {
  final hemi = lat >= 0 ? 'N' : 'S';
  return _dms(lat.abs(), hemi);
}

/// Formats a longitude value as `W071°00'28.8"`.
String formatLonDMS(double lon) {
  final hemi = lon >= 0 ? 'E' : 'W';
  return _dms(lon.abs(), hemi);
}

/// Formats a coordinate pair as `N4221.5 W07100.5` (ARINC position format).
String formatArinc(double lat, double lon) {
  final latHemi = lat >= 0 ? 'N' : 'S';
  final latAbs = lat.abs();
  final latDeg = latAbs.floor();
  final latMin = (latAbs - latDeg) * 60;

  final lonHemi = lon >= 0 ? 'E' : 'W';
  final lonAbs = lon.abs();
  final lonDeg = lonAbs.floor();
  final lonMin = (lonAbs - lonDeg) * 60;

  return '$latHemi${latDeg.toString().padLeft(2, '0')}'
      '${latMin.toStringAsFixed(1).padLeft(4, '0')} '
      '$lonHemi${lonDeg.toString().padLeft(3, '0')}'
      '${lonMin.toStringAsFixed(1).padLeft(4, '0')}';
}

// ── Internal ────────────────────────────────────────────────────────────────

double _toRad(double deg) => deg * math.pi / 180;

double _toDeg(double rad) => rad * 180 / math.pi;

String _dms(double absVal, String hemi) {
  final deg = absVal.floor();
  final minFull = (absVal - deg) * 60;
  final min = minFull.floor();
  final sec = (minFull - min) * 60;
  return '$hemi${deg.toString().padLeft(2, '0')}°'
      "${min.toString().padLeft(2, '0')}'"
      '${sec.toStringAsFixed(1).padLeft(4, '0')}"';
}

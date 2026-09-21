import 'dart:math' as math;

/// Sunrise/sunset calculation (NOAA solar computation approximation,
/// atmosphere refraction 0.833°). Pure Dart — used by the inspector's
/// airport overview tab ("日出和日落时间").

class SunTimes {
  const SunTimes({this.sunrise, this.sunset});

  /// UTC timestamps; `null` on polar day/night.
  final DateTime? sunrise;
  final DateTime? sunset;

  bool get isEmpty => sunrise == null && sunset == null;
}

/// Computes sunrise & sunset for [latitude]/[longitude] on the UTC date of
/// [date] (defaults to now). Returns empty times in polar day/night.
SunTimes computeSunTimes(double latitude, double longitude, [DateTime? date]) {
  final utcDate = (date ?? DateTime.now().toUtc()).toUtc();
  final julianDay = _julianDayAtMidnightUtc(utcDate);
  // Epoch must be J2000 MIDNIGHT (2451544.5) to match our midnight-based
  // Julian day — using 2451545.0 (J2000 noon) shifts everything by 12 h.
  final n = julianDay - 2451544.5;

  // Mean solar time, longitude in degrees east positive.
  final jStar = n - longitude / 360.0;

  // Solar mean anomaly & ecliptic longitude (degrees).
  final m = _norm360(357.5291 + 0.98560028 * jStar);
  final c =
      1.9148 * _sinDeg(m) + 0.0200 * _sinDeg(2 * m) + 0.0003 * _sinDeg(3 * m);
  final lambda = _norm360(m + c + 180 + 102.9372);

  // Solar transit (Julian day) and declination.
  final jTransit =
      2451545.0 + jStar + 0.0053 * _sinDeg(m) - 0.0069 * _sinDeg(2 * lambda);
  final delta = _asinDeg(_sinDeg(lambda) * _sinDeg(23.4397));

  // Hour angle for the sun's upper limb touching the horizon (-0.833°).
  final cosOmega =
      (_sinDeg(-0.833) - _sinDeg(latitude) * _sinDeg(delta)) /
      (_cosDeg(latitude) * _cosDeg(delta));
  if (cosOmega > 1) return const SunTimes(); // Polar night.
  if (cosOmega < -1) return const SunTimes(); // Midnight sun.
  final omega = _acosDeg(cosOmega);

  return SunTimes(
    sunrise: _fromJulianDay(jTransit - omega / 360.0),
    sunset: _fromJulianDay(jTransit + omega / 360.0),
  );
}

double _norm360(double v) => v - 360.0 * (v / 360.0).floorToDouble();

double _sinDeg(double d) => _sin(d * _pi / 180);

double _cosDeg(double d) => _cos(d * _pi / 180);

double _asinDeg(double x) => _asin(x.clamp(-1.0, 1.0)) * 180 / _pi;

double _acosDeg(double x) => _acos(x.clamp(-1.0, 1.0)) * 180 / _pi;

const double _pi = 3.1415926535897932;

double _sin(double x) => math.sin(x);

double _cos(double x) => math.cos(x);

double _asin(double x) => math.asin(x);

double _acos(double x) => math.acos(x);

/// Julian day at 0h UT of [date]'s calendar day.
double _julianDayAtMidnightUtc(DateTime date) {
  var y = date.year;
  var m = date.month;
  final d = date.day;
  if (m <= 2) {
    y -= 1;
    m += 12;
  }
  final a = (y / 100).floor();
  final b = 2 - a + (a / 4).floor();
  return (365.25 * (y + 4716)).floor() +
      (30.6001 * (m + 1)).floor() +
      d +
      b -
      1524.5;
}

DateTime _fromJulianDay(double jd) {
  final msSinceJ2000 = (jd - 2440587.5) * 86400000.0;
  return DateTime.fromMillisecondsSinceEpoch(msSinceJ2000.round(), isUtc: true);
}

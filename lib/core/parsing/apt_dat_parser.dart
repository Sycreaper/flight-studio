import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import '../../../core/geo/geo_math.dart';
import '../../../data/db/database.dart';
import 'earth_nav_parser.dart' show ProgressCallback;

/// One runway parsed from an apt.dat block — kept in memory only until the
/// airport closes so we can pick the longest for the airport's position.
class _RunwayCandidate {
  _RunwayCandidate({
    required this.ident,
    required this.latitude,
    required this.longitude,
    required this.lengthFt,
    required this.headingDeg,
    required this.surface,
  });

  final String ident; // e.g. '16L' / '36' / 'W'
  final double latitude; // midpoint
  final double longitude;
  final double lengthFt;
  final double headingDeg;
  final String surface;
}

/// Streams X-Plane `apt.dat` and inserts airports + runways into the Drift
/// database.
///
/// The file is a sequence of airport **blocks**, each starting with a header
/// row and terminated by row `99`:
///
/// - Row `1`  — land airport header: `1 <elev_ft> ? ? <icao> <name…>`
/// - Row `16` — seaplane base header (same layout)
/// - Row `17` — heliport header (same layout)
/// - Row `100` — land runway:
///   `100 <width_m> <surface> … <num1> <lat1> <lon1> … <num2> <lat2> <lon2> …`
///   Column indices follow atools `RunwayFieldIndex`:
///   8=primary number, 9/10=primary lat/lon, 17=secondary number, 18/19=secondary lat/lon.
/// - Row `101` — water runway: 3/4/5=primary, 6/7/8=secondary.
/// - Row `102` — helipad: 1=lat, 2=lon.
///
/// The airport's map position is the **midpoint of its longest runway**
/// (Little Navmap's approach when no datum row exists); heliports fall back
/// to the first helipad position.
///
/// The global apt.dat is ~363 MB, so this parser streams line-by-line and
/// never loads the whole file into memory.
///
/// Pass `replace: true` for custom-scenery files so their airports override
/// the global ones; global files use `ignore` (first write wins).
Future<int> importAptDat(
  File file,
  NavdataDatabase db, {
  ProgressCallback? onProgress,
  bool replace = false,
}) async {
  var airportCount = 0;
  var lineNo = 0;
  final airportBatch = <AirportsCompanion>[];
  final runwayBatch = <RunwaysCompanion>[];

  // Per-airport accumulation state.
  var hdrIcao = '';
  var hdrName = '';
  var hdrElev = 0.0;
  var hdrType = 'airport';
  var inAirport = false;
  final runways = <_RunwayCandidate>[];
  (double, double)? helipadPos; // (lat, lon) fallback for heliports.

  Future<void> flushAirport() async {
    if (!inAirport || hdrIcao.isEmpty) return;

    double? lat;
    double? lon;
    if (runways.isNotEmpty) {
      // Longest runway midpoint wins (LNM behaviour).
      _RunwayCandidate longest = runways.reduce(
        (a, b) => a.lengthFt >= b.lengthFt ? a : b,
      );
      lat = longest.latitude;
      lon = longest.longitude;
    } else if (helipadPos != null) {
      lat = helipadPos.$1;
      lon = helipadPos.$2;
    }
    if (lat == null || lon == null) return; // Positionless — skip.

    airportBatch.add(
      AirportsCompanion.insert(
        icao: hdrIcao,
        name: hdrName,
        latitude: lat,
        longitude: lon,
        elevationFt: Value(hdrElev),
        type: hdrType,
        source: 'xplane',
      ),
    );
    for (final rw in runways) {
      runwayBatch.add(
        RunwaysCompanion.insert(
          airportIcao: hdrIcao,
          ident: rw.ident,
          latitude: rw.latitude,
          longitude: rw.longitude,
          lengthFt: rw.lengthFt,
          headingDeg: rw.headingDeg,
          surface: Value(rw.surface.isEmpty ? null : rw.surface),
        ),
      );
    }

    airportCount++;
    if (airportBatch.length >= 500) {
      await db.batch(
        (b) => b.insertAll(
          db.airports,
          airportBatch,
          mode: replace
              ? InsertMode.insertOrReplace
              : InsertMode.insertOrIgnore,
        ),
      );
      airportBatch.clear();
    }
    if (runwayBatch.length >= 2000) {
      await db.batch(
        (b) => b.insertAll(
          db.runways,
          runwayBatch,
          mode: replace
              ? InsertMode.insertOrReplace
              : InsertMode.insertOrIgnore,
        ),
      );
      runwayBatch.clear();
    }
  }

  final stream = file
      .openRead()
      .transform(const Utf8Decoder(allowMalformed: true))
      .transform(const LineSplitter());

  await for (final rawLine in stream) {
    lineNo++;
    final line = rawLine.trim();
    if (line.isEmpty || line == 'A') continue;
    if (line.contains('Version') || line.contains('Generated')) continue;

    final parts = line.split(RegExp(r'\s+'));
    final code = int.tryParse(parts[0]);

    switch (code) {
      case 1: // Land airport header.
      case 16: // Seaplane base header.
      case 17: // Heliport header.
        await flushAirport();
        inAirport = true;
        hdrIcao = parts.length > 4 ? parts[4] : '';
        hdrName = parts.length > 5 ? parts.sublist(5).join(' ') : '';
        hdrElev = parts.length > 1 ? (double.tryParse(parts[1]) ?? 0) : 0;
        hdrType = code == 16
            ? 'seaplane'
            : code == 17
            ? 'heliport'
            : 'airport';
        runways.clear();
        helipadPos = null;
        break;

      case 100: // Land runway.
        if (!inAirport || parts.length < 20) break;
        _addLandRunway(parts, runways);
        break;

      case 101: // Water runway.
        if (!inAirport || parts.length < 9) break;
        _addWaterRunway(parts, runways);
        break;

      case 102: // Helipad — position fallback.
        if (!inAirport || parts.length < 3) break;
        final hLat = double.tryParse(parts[1]);
        final hLon = double.tryParse(parts[2]);
        if (hLat != null && hLon != null && helipadPos == null) {
          helipadPos = (hLat, hLon);
        }
        break;

      case 99: // End of airport block.
        await flushAirport();
        inAirport = false;
        runways.clear();
        helipadPos = null;
        break;
    }

    if (onProgress != null && lineNo % 20000 == 0) {
      onProgress(lineNo, _aptLineEstimate, 'Importing airports…');
    }
  }
  await flushAirport(); // File may end without a trailing 99.

  if (airportBatch.isNotEmpty) {
    await db.batch(
      (b) => b.insertAll(
        db.airports,
        airportBatch,
        mode: replace ? InsertMode.insertOrReplace : InsertMode.insertOrIgnore,
      ),
    );
  }
  if (runwayBatch.isNotEmpty) {
    await db.batch(
      (b) => b.insertAll(
        db.runways,
        runwayBatch,
        mode: replace ? InsertMode.insertOrReplace : InsertMode.insertOrIgnore,
      ),
    );
  }

  onProgress?.call(1, 1, 'Airports done ($airportCount)');
  return airportCount;
}

const int _aptLineEstimate = 8000000; // ~8M lines in the global apt.dat.

void _addLandRunway(List<String> parts, List<_RunwayCandidate> out) {
  // atools RunwayFieldIndex: 8=primary number, 9/10=primary lat/lon,
  // 17=secondary number, 18/19=secondary lat/lon; 2=surface.
  final lat1 = double.tryParse(parts[9]);
  final lon1 = double.tryParse(parts[10]);
  final lat2 = double.tryParse(parts[18]);
  final lon2 = double.tryParse(parts[19]);
  if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) return;

  final num1 = parts[8];
  final num2 = parts[17];
  final surface = _surfaceName(int.tryParse(parts[2]) ?? 1);

  final midLat = (lat1 + lat2) / 2;
  final midLon = (lon1 + lon2) / 2;
  final lengthFt = haversineNm(lat1, lon1, lat2, lon2) * 6076.12;
  final heading = initialBearing(lat1, lon1, lat2, lon2);

  final ident = num1.isNotEmpty ? num1 : num2;
  out.add(
    _RunwayCandidate(
      ident: ident,
      latitude: midLat,
      longitude: midLon,
      lengthFt: lengthFt,
      headingDeg: heading,
      surface: surface,
    ),
  );
}

void _addWaterRunway(List<String> parts, List<_RunwayCandidate> out) {
  // atools: 3/4/5 = primary number/lat/lon; 6/7/8 = secondary number/lat/lon.
  final lat1 = double.tryParse(parts[4]);
  final lon1 = double.tryParse(parts[5]);
  final lat2 = double.tryParse(parts[7]);
  final lon2 = double.tryParse(parts[8]);
  if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) return;

  final midLat = (lat1 + lat2) / 2;
  final midLon = (lon1 + lon2) / 2;
  final lengthFt = haversineNm(lat1, lon1, lat2, lon2) * 6076.12;
  final heading = initialBearing(lat1, lon1, lat2, lon2);

  final ident = parts[3].isNotEmpty ? parts[3] : parts[6];
  out.add(
    _RunwayCandidate(
      ident: ident,
      latitude: midLat,
      longitude: midLon,
      lengthFt: lengthFt,
      headingDeg: heading,
      surface: 'water',
    ),
  );
}

String _surfaceName(int code) {
  switch (code) {
    case 1:
      return 'asphalt';
    case 2:
      return 'concrete';
    case 3:
      return 'turf';
    case 4:
      return 'dirt';
    case 5:
      return 'gravel';
    case 12:
      return 'drylakebed';
    case 13:
      return 'water';
    case 14:
      return 'snow';
    case 15:
      return 'transparent';
    default:
      return '';
  }
}

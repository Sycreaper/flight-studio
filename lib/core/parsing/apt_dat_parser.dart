import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import '../../../core/geo/geo_math.dart';
import '../../../data/db/database.dart';
import 'earth_nav_parser.dart' show ProgressCallback;

/// One runway STRIP parsed from an apt.dat block — both ends. Kept in memory
/// only until the airport closes so we can pick the longest strip for the
/// airport's position.
class _RunwayStrip {
  _RunwayStrip({
    required this.ident1,
    required this.lat1,
    required this.lon1,
    required this.ident2,
    required this.lat2,
    required this.lon2,
    required this.lengthFt,
    required this.heading1Deg,
    required this.heading2Deg,
    required this.surface,
  });

  // End 1 (threshold position + its own true heading).
  final String ident1;
  final double lat1;
  final double lon1;
  final double heading1Deg;

  // End 2 (reciprocal direction).
  final String ident2;
  final double lat2;
  final double lon2;
  final double heading2Deg;

  final double lengthFt;
  final String surface;

  /// Strip midpoint — the airport's map position (LNM behaviour).
  double get midLat => (lat1 + lat2) / 2;

  double get midLon => (lon1 + lon2) / 2;
}

/// One ATC frequency parsed from apt.dat rows 50–56.
class _FrequencyCandidate {
  _FrequencyCandidate({
    required this.type,
    required this.frequencyKhz,
    required this.description,
  });

  final String type; // 'ATIS' / 'CTAF' / 'GND' / 'TWR' / 'CLD' / 'APP' / 'DEP'
  final int frequencyKhz;
  final String description;
}

/// Maps apt.dat frequency row codes to stable type strings.
String _frequencyType(int code) => switch (code) {
  50 => 'ATIS',
  51 => 'CTAF',
  52 => 'GND',
  53 => 'TWR',
  54 => 'CLD',
  55 => 'APP',
  56 => 'DEP',
  _ => 'UNKNOWN',
};

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
/// - Rows `50`–`56` — ATC frequencies (ATIS/CTAF/GND/TWR/CLD/APP/DEP),
///   stored in kHz: `53 119500 TOWER`.
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
  final frequencyBatch = <FrequenciesCompanion>[];

  // Per-airport accumulation state.
  var hdrIcao = '';
  var hdrName = '';
  var hdrElev = 0.0;
  double? hdrMagvar;
  var hdrType = 'airport';
  var inAirport = false;
  final runways = <_RunwayStrip>[];
  final frequencies = <_FrequencyCandidate>[];
  (double, double)? helipadPos; // (lat, lon) fallback for heliports.

  Future<void> flushAirport() async {
    if (!inAirport || hdrIcao.isEmpty) return;

    double? lat;
    double? lon;
    if (runways.isNotEmpty) {
      // Longest STRIP midpoint wins (LNM behaviour).
      _RunwayStrip longest = runways.reduce(
        (a, b) => a.lengthFt >= b.lengthFt ? a : b,
      );
      lat = longest.midLat;
      lon = longest.midLon;
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
        magvarDeg: Value(hdrMagvar),
        type: hdrType,
        source: 'xplane',
      ),
    );
    // BOTH runway ends are stored — runways come in pairs (16L/34R), each
    // end with its own threshold position and reciprocal heading. stripIndex
    // tags the physical strip so the inspector can group `16L/34R` together.
    for (var i = 0; i < runways.length; i++) {
      final rw = runways[i];
      runwayBatch.addAll([
        RunwaysCompanion.insert(
          airportIcao: hdrIcao,
          ident: rw.ident1,
          latitude: rw.lat1,
          longitude: rw.lon1,
          lengthFt: rw.lengthFt,
          headingDeg: rw.heading1Deg,
          surface: Value(rw.surface.isEmpty ? null : rw.surface),
          stripIndex: Value(i),
        ),
        RunwaysCompanion.insert(
          airportIcao: hdrIcao,
          ident: rw.ident2,
          latitude: rw.lat2,
          longitude: rw.lon2,
          lengthFt: rw.lengthFt,
          headingDeg: rw.heading2Deg,
          surface: Value(rw.surface.isEmpty ? null : rw.surface),
          stripIndex: Value(i),
        ),
      ]);
    }
    for (final fr in frequencies) {
      frequencyBatch.add(
        FrequenciesCompanion.insert(
          airportIcao: hdrIcao,
          type: fr.type,
          frequencyKhz: fr.frequencyKhz,
          description: Value(fr.description.isEmpty ? null : fr.description),
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
    if (frequencyBatch.length >= 2000) {
      await db.batch(
        (b) => b.insertAll(
          db.frequencies,
          frequencyBatch,
          mode: replace
              ? InsertMode.insertOrReplace
              : InsertMode.insertOrIgnore,
        ),
      );
      frequencyBatch.clear();
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
        // Field 3 is the (deprecated) magnetic declination — atools reads
        // it the same way; most 1200-era files still carry a real value.
        hdrMagvar = parts.length > 3 ? double.tryParse(parts[3]) : null;
        hdrType = code == 16
            ? 'seaplane'
            : code == 17
            ? 'heliport'
            : 'airport';
        runways.clear();
        frequencies.clear();
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

      case 50: // ATIS.
      case 51: // CTAF (unicom).
      case 52: // Ground.
      case 53: // Tower.
      case 54: // Clearance delivery.
      case 55: // Approach.
      case 56: // Departure.
        if (!inAirport || parts.length < 2) break;
        final khz = int.tryParse(parts[1]);
        if (khz == null) break;
        frequencies.add(
          _FrequencyCandidate(
            type: _frequencyType(code!),
            frequencyKhz: khz,
            description: parts.length > 2 ? parts.sublist(2).join(' ') : '',
          ),
        );
        break;

      case 99: // End of airport block.
        await flushAirport();
        inAirport = false;
        runways.clear();
        frequencies.clear();
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
  if (frequencyBatch.isNotEmpty) {
    await db.batch(
      (b) => b.insertAll(
        db.frequencies,
        frequencyBatch,
        mode: replace ? InsertMode.insertOrReplace : InsertMode.insertOrIgnore,
      ),
    );
  }

  onProgress?.call(1, 1, 'Airports done ($airportCount)');
  return airportCount;
}

const int _aptLineEstimate = 8000000; // ~8M lines in the global apt.dat.

void _addLandRunway(List<String> parts, List<_RunwayStrip> out) {
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

  final lengthFt = haversineNm(lat1, lon1, lat2, lon2) * 6076.12;
  // Each runway end's number reflects the heading FROM its own threshold
  // towards the opposite end (e.g. 16L lands heading ~160°).
  final heading1 = initialBearing(lat1, lon1, lat2, lon2);
  final heading2 = initialBearing(lat2, lon2, lat1, lon1);

  out.add(
    _RunwayStrip(
      ident1: num1,
      lat1: lat1,
      lon1: lon1,
      heading1Deg: heading1,
      ident2: num2,
      lat2: lat2,
      lon2: lon2,
      heading2Deg: heading2,
      lengthFt: lengthFt,
      surface: surface,
    ),
  );
}

void _addWaterRunway(List<String> parts, List<_RunwayStrip> out) {
  // atools: 3/4/5 = primary number/lat/lon; 6/7/8 = secondary number/lat/lon.
  final lat1 = double.tryParse(parts[4]);
  final lon1 = double.tryParse(parts[5]);
  final lat2 = double.tryParse(parts[7]);
  final lon2 = double.tryParse(parts[8]);
  if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) return;

  final lengthFt = haversineNm(lat1, lon1, lat2, lon2) * 6076.12;
  final heading1 = initialBearing(lat1, lon1, lat2, lon2);
  final heading2 = initialBearing(lat2, lon2, lat1, lon1);

  out.add(
    _RunwayStrip(
      ident1: parts[3],
      lat1: lat1,
      lon1: lon1,
      heading1Deg: heading1,
      ident2: parts[6],
      lat2: lat2,
      lon2: lon2,
      heading2Deg: heading2,
      lengthFt: lengthFt,
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

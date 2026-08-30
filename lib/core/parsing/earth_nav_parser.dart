import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import '../../../data/db/database.dart';

/// Callback for progress reporting during import.
typedef ProgressCallback =
    void Function(int current, int total, String message);

/// Total line estimate used for progress before the count is known (the
/// streaming apt.dat reader can't know the line count up front).
const int _progressLineEstimate = 400000;

/// Classifies an earth_nav.dat type-3 (VOR family) row into its subtype by
/// inspecting the human-readable name suffix — the approach Little Navmap's
/// `XpNavReader::writeVor` uses.
///
/// Suffixes seen in real data: `VOR`, `VOR/DME`, `VORTAC`, `TACAN`.
/// VORTAC must be tested **before** TACAN (it contains "TACAN").
String classifyVorName(String name) {
  final n = name.toUpperCase();
  if (n.contains('VORTAC')) return 'VORTAC';
  if (n.contains('TACAN')) return 'TACAN';
  if (n.contains('VOR/DME') || n.contains('VOR-DME')) return 'VOR/DME';
  return 'VOR';
}

/// Maps an earth_nav.dat row code to the internal navaid type string.
/// Returns an empty string for rows we intentionally skip.
///
/// Codes verified against atools `xpconstants.h::NavRowCode` and the real
/// Navigraph 2607 dataset:
/// - 2 NDB · 3 VOR family · 4 LOC(ILS) · 5 LOC-only · 6 GS · 7 OM · 8 MM
///   · 9 IM · 12 paired DME (skipped — duplicate of the type-3 row) ·
///   13 standalone DME · 14/16 SBAS points (skipped) · 15 GLS/GBAS.
String navTypeFromCode(int code, String name) {
  switch (code) {
    case 2:
      return 'NDB';
    case 3:
      return classifyVorName(name);
    case 4:
      return 'ILS';
    case 5:
      return 'LOC';
    case 6:
      return 'GS';
    case 7:
      return 'OM';
    case 8:
      return 'MM';
    case 9:
      return 'IM';
    case 13:
      return 'DME';
    case 15:
      return 'GLS';
    case 12: // Paired DME — same coordinates as its type-3 row.
    case 14: // SBAS/GBAS final approach point.
    case 16: // SBAS/GBAS threshold point.
    default:
      return '';
  }
}

/// Streams X-Plane `earth_nav.dat` and inserts every navaid into the Drift
/// database. Uses line streaming so a multi-MB file never loads fully into
/// memory.
///
/// Format (one navaid per line, space-delimited):
/// ```
/// code lat lon elev_ft freq range_magvar ident facility region name...
/// ```
Future<int> importEarthNav(
  File file,
  NavdataDatabase db, {
  ProgressCallback? onProgress,
}) async {
  var count = 0;
  var lineNo = 0;
  final batch = <NavaidsCompanion>[];

  final stream = file
      .openRead()
      .transform(const Utf8Decoder(allowMalformed: true))
      .transform(const LineSplitter());

  await for (final rawLine in stream) {
    lineNo++;
    final line = rawLine.trim();
    if (line.isEmpty || line == '99' || line == 'I') continue;
    if (line.contains('Version') || line.contains('Copyright')) continue;

    final parts = line.split(RegExp(r'\s+'));
    if (parts.length < 11) continue;

    final typeCode = int.tryParse(parts[0]);
    if (typeCode == null) continue;

    final lat = double.tryParse(parts[1]);
    final lon = double.tryParse(parts[2]);
    if (lat == null || lon == null) continue;

    final elev = int.tryParse(parts[3]) ?? 0;
    final freqRaw = int.tryParse(parts[4]) ?? 0;
    final rangeNm = double.tryParse(parts[5]) ?? 0;
    final ident = parts[7];
    // parts[8] = facility code (ENRT or airport ICAO); parts[9] = ICAO region.
    // The human-readable name starts at parts[10].
    final name = parts.sublist(10).join(' ');

    final navType = navTypeFromCode(typeCode, name);
    if (navType.isEmpty) continue;

    batch.add(
      NavaidsCompanion.insert(
        ident: ident,
        name: Value(name),
        type: navType,
        frequencyKhz: freqRaw.toDouble(),
        latitude: lat,
        longitude: lon,
        elevationFt: Value(elev.toDouble()),
        dmeRangeNm: Value(rangeNm),
        source: 'xplane',
      ),
    );

    if (batch.length >= 1000) {
      await db.batch(
        (b) => b.insertAll(db.navaids, batch, mode: InsertMode.insertOrIgnore),
      );
      batch.clear();
    }

    count++;
    if (onProgress != null && lineNo % 1000 == 0) {
      onProgress(lineNo, _progressLineEstimate, 'Importing navaids…');
    }
  }

  if (batch.isNotEmpty) {
    await db.batch(
      (b) => b.insertAll(db.navaids, batch, mode: InsertMode.insertOrIgnore),
    );
  }

  onProgress?.call(1, 1, 'Navaids done ($count)');
  return count;
}

/// Streams X-Plane `earth_fix.dat` and inserts all waypoints/intersections.
Future<int> importEarthFix(
  File file,
  NavdataDatabase db, {
  ProgressCallback? onProgress,
}) async {
  var count = 0;
  var lineNo = 0;
  final batch = <FixesCompanion>[];

  final stream = file
      .openRead()
      .transform(const Utf8Decoder(allowMalformed: true))
      .transform(const LineSplitter());

  await for (final rawLine in stream) {
    lineNo++;
    final line = rawLine.trim();
    if (line.isEmpty || line == '99' || line == 'I') continue;
    if (line.contains('Version') || line.contains('Copyright')) continue;
    if (!RegExp(r'^-?\d').hasMatch(line)) continue;

    final parts = line.split(RegExp(r'\s+'));
    if (parts.length < 3) continue;

    final lat = double.tryParse(parts[0]);
    final lon = double.tryParse(parts[1]);
    if (lat == null || lon == null) continue;

    final ident = parts[2];
    final description = parts.length > 3 ? parts.sublist(3).join(' ') : '';

    batch.add(
      FixesCompanion.insert(
        ident: ident,
        latitude: lat,
        longitude: lon,
        description: Value(description),
        source: 'xplane',
      ),
    );

    if (batch.length >= 1000) {
      await db.batch(
        (b) => b.insertAll(db.fixes, batch, mode: InsertMode.insertOrIgnore),
      );
      batch.clear();
    }

    count++;
    if (onProgress != null && lineNo % 10000 == 0) {
      onProgress(lineNo, _progressLineEstimate, 'Importing waypoints…');
    }
  }

  if (batch.isNotEmpty) {
    await db.batch(
      (b) => b.insertAll(db.fixes, batch, mode: InsertMode.insertOrIgnore),
    );
  }

  onProgress?.call(1, 1, 'Waypoints done ($count)');
  return count;
}

/// Streams X-Plane `earth_awy.dat` and inserts all airway segments.
///
/// Format (11 columns):
/// ```
/// start_ident start_region start_type end_ident end_region end_type
/// direction(7) class_flag(8: 1=low/Victor 2=high/Jet) base(9) top(10)
/// airway_name(11)
/// ```
Future<int> importEarthAwy(
  File file,
  NavdataDatabase db, {
  ProgressCallback? onProgress,
}) async {
  var count = 0;
  var lineNo = 0;
  final batch = <AirwaysCompanion>[];

  final stream = file
      .openRead()
      .transform(const Utf8Decoder(allowMalformed: true))
      .transform(const LineSplitter());

  await for (final rawLine in stream) {
    lineNo++;
    final line = rawLine.trim();
    if (line.isEmpty || line == '99' || line == 'I') continue;
    if (line.contains('Version') || line.contains('Copyright')) continue;
    if (!RegExp(r'^[A-Z0-9]').hasMatch(line)) continue;

    final parts = line.split(RegExp(r'\s+'));
    if (parts.length != 11) continue;
    if (!{'N', 'F', 'B'}.contains(parts[6])) continue;
    if (double.tryParse(parts[7]) == null) continue; // class flag
    if (double.tryParse(parts[8]) == null) continue; // base altitude
    if (double.tryParse(parts[9]) == null) continue; // top altitude

    final startIdent = parts[0];
    final startType = parts[2];
    final endIdent = parts[3];
    final endType = parts[5];
    final direction = parts[6];
    final baseAlt = double.tryParse(parts[8]);
    final topAlt = double.tryParse(parts[9]);
    final airwayName = parts[10];

    batch.add(
      AirwaysCompanion.insert(
        name: airwayName,
        startIdent: startIdent,
        endIdent: endIdent,
        startType: startType,
        endType: endType,
        baseFlightLevel: Value(baseAlt),
        topFlightLevel: Value(topAlt),
        direction: Value(direction),
        source: 'xplane',
      ),
    );

    if (batch.length >= 1000) {
      await db.batch(
        (b) => b.insertAll(db.airways, batch, mode: InsertMode.insertOrIgnore),
      );
      batch.clear();
    }

    count++;
    if (onProgress != null && lineNo % 10000 == 0) {
      onProgress(lineNo, _progressLineEstimate, 'Importing airways…');
    }
  }

  if (batch.isNotEmpty) {
    await db.batch(
      (b) => b.insertAll(db.airways, batch, mode: InsertMode.insertOrIgnore),
    );
  }

  onProgress?.call(1, 1, 'Airways done ($count)');
  return count;
}

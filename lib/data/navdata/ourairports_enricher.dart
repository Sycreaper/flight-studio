import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:path/path.dart' as p;

import '../../l10n/import_messages.dart';
import '../db/database.dart';

/// Enriches the imported airports table with IATA codes, city/municipality
/// and ISO country from the **OurAirports** dataset (public domain) — the
/// same metadata source Little Navmap uses to fill these fields for
/// X-Plane-based navdata (apt.dat itself carries none of them).
///
/// The `airports.csv` (~9 MB) is downloaded once into the app support
/// directory and cached; every navdata import afterwards enriches from the
/// local copy. Any failure (offline, bad CSV) degrades gracefully — the
/// fields simply stay empty, exactly like before.
class OurAirportsEnricher {
  OurAirportsEnricher._();

  static final OurAirportsEnricher instance = OurAirportsEnricher._();

  static const csvUrl =
      'https://davidmegginson.github.io/ourairports-data/airports.csv';

  final Dio _dio = Dio()
    ..options.connectTimeout = const Duration(seconds: 15)
    ..options.receiveTimeout = const Duration(minutes: 2);

  /// Enriches [db]'s airports with iata/city/country. Reports human-readable
  /// progress via [onMessage]. [csvTextOverride] skips the cache/download
  /// (tests). Never throws.
  Future<void> enrich(
    NavdataDatabase db, {
    required Future<Directory> Function() supportDir,
    void Function(String message)? onMessage,
    String? csvTextOverride,
  }) async {
    try {
      final csv =
          csvTextOverride ??
          await _loadCsv(await supportDir(), onMessage: onMessage);
      if (csv == null || csv.isEmpty) return;
      onMessage?.call(ImportMessages.enrichingAirports);

      final rows = parseAirportCsv(csv);
      if (rows.isEmpty) return;

      final airports = await db.select(db.airports).get();
      var updated = 0;
      await db.transaction(() async {
        for (final airport in airports) {
          final meta = rows[airport.icao.toUpperCase()];
          if (meta == null) continue;
          final iata = meta.$1;
          final city = meta.$2;
          final country = meta.$3;
          if (iata == null && city == null && country == null) continue;
          await (db.update(
            db.airports,
          )..where((t) => t.icao.equals(airport.icao))).write(
            AirportsCompanion(
              iata: drift.Value(iata),
              city: drift.Value(city),
              country: drift.Value(country),
            ),
          );
          updated++;
        }
      });
      onMessage?.call(ImportMessages.enrichedAirports(updated));
    } on Exception catch (_) {
      // Offline / bad data — the fields just stay as they were.
    } on Error catch (_) {
      // Same.
    }
  }

  /// Returns the cached CSV text, downloading it first when absent. `null`
  /// when the download fails and no cache exists.
  Future<String?> _loadCsv(
    Directory supportDir, {
    void Function(String message)? onMessage,
  }) async {
    final cache = File(p.join(supportDir.path, 'ourairports', 'airports.csv'));
    if (await cache.exists()) {
      final text = await cache.readAsString();
      return text.isEmpty ? null : text;
    }
    onMessage?.call(ImportMessages.downloadingOurAirports);
    final response = await _dio.get<String>(csvUrl);
    final text = response.data;
    if (text == null || text.isEmpty) return null;
    await cache.parent.create(recursive: true);
    await cache.writeAsString(text, flush: true);
    return text;
  }
}

/// Minimal RFC-4180 CSV parser (OurAirports quotes fields containing commas).
List<List<String>> parseCsv(String text) {
  final rows = <List<String>>[];
  final field = StringBuffer();
  final row = <String>[];
  var inQuotes = false;
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(ch);
      }
      continue;
    }
    switch (ch) {
      case '"':
        inQuotes = true;
      case ',':
        row.add(field.toString());
        field.clear();
      case '\r':
        break;
      case '\n':
        row.add(field.toString());
        field.clear();
        if (row.length > 1 || row.first.isNotEmpty) {
          rows.add(List<String>.of(row));
        }
        row.clear();
      default:
        field.write(ch);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    if (row.length > 1 || row.first.isNotEmpty) {
      rows.add(List<String>.of(row));
    }
  }
  return rows;
}

/// Maps OurAirports `airports.csv` text to
/// `ICAO → (iata, municipality, isoCountry)`.
Map<String, (String?, String?, String?)> parseAirportCsv(String text) {
  final rows = parseCsv(text);
  if (rows.isEmpty) return const {};
  final header = rows.first;
  int indexOf(String name) => header.indexOf(name);
  final iIdent = indexOf('ident');
  final iIata = indexOf('iata_code');
  final iCity = indexOf('municipality');
  final iCountry = indexOf('iso_country');
  final iType = indexOf('type');
  if (iIdent == -1) return const {};

  String? clean(String? s) {
    if (s == null) return null;
    final v = s.trim();
    return v.isEmpty ? null : v;
  }

  String? cell(List<String> r, int i) =>
      i >= 0 && i < r.length ? clean(r[i]) : null;

  final result = <String, (String?, String?, String?)>{};
  for (var i = 1; i < rows.length; i++) {
    final r = rows[i];
    final ident = cell(r, iIdent)?.toUpperCase();
    if (ident == null) continue;
    final type = cell(r, iType) ?? '';
    // Skip non-aerodromes — they only add noise.
    if (type == 'balloonport' || type == 'closed') continue;
    result[ident] = (cell(r, iIata), cell(r, iCity), cell(r, iCountry));
  }
  return result;
}

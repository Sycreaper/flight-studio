import 'package:dio/dio.dart';

/// Live weather for one airport (raw METAR + TAF text).
class AirportWeather {
  const AirportWeather({
    required this.icao,
    this.metar,
    this.metarObsTime,
    this.taf,
  });

  final String icao;
  final String? metar;
  final DateTime? metarObsTime;
  final String? taf;

  bool get isEmpty => metar == null && taf == null;
}

/// Free, key-less online weather source (NOAA aviationweather.gov JSON API).
/// Temporary arrangement until a dedicated weather pipeline (sim weather /
/// NOAA GRIB2, roadmap) replaces it.
///
/// Responses are cached for 10 minutes per station so re-selecting the same
/// airport doesn't re-hit the network. All failures degrade to `null` — the
/// inspector simply hides the weather section.
class WeatherService {
  WeatherService._() {
    _dio.options
      ..connectTimeout = const Duration(seconds: 8)
      ..receiveTimeout = const Duration(seconds: 8)
      ..headers['accept'] = 'application/json';
  }

  static final WeatherService instance = WeatherService._();

  static const _metarUrl = 'https://aviationweather.gov/api/data/metar';
  static const _tafUrl = 'https://aviationweather.gov/api/data/taf';
  static const _ttl = Duration(minutes: 10);

  final Dio _dio = Dio();
  final Map<String, DateTime> _fetchedAt = {};
  final Map<String, AirportWeather> _cache = {};

  /// Fetches METAR + TAF for [icao]; cached for 10 minutes. Returns `null`
  /// when the station has no data or the network fails.
  Future<AirportWeather?> fetch(String icao) async {
    final id = icao.toUpperCase();
    final at = _fetchedAt[id];
    if (at != null && DateTime.now().difference(at) < _ttl) {
      final cached = _cache[id];
      return cached == null || cached.isEmpty ? null : cached;
    }

    final results = await Future.wait([_fetchMetar(id), _fetchTaf(id)]);
    final weather = AirportWeather(
      icao: id,
      metar: results[0].metar,
      metarObsTime: results[0].metarObsTime,
      taf: results[1].taf,
    );
    _cache[id] = weather;
    _fetchedAt[id] = DateTime.now();
    return weather.isEmpty ? null : weather;
  }

  Future<AirportWeather> _fetchMetar(String icao) async {
    try {
      final res = await _dio.get<List<dynamic>>(
        _metarUrl,
        queryParameters: {'ids': icao, 'format': 'json'},
      );
      if (res.data == null || res.data!.isEmpty) {
        return AirportWeather(icao: icao);
      }
      final row = res.data!.first as Map<String, dynamic>;
      return AirportWeather(
        icao: icao,
        // Field is 'rawOb' in the aviationweather.gov JSON response.
        metar: (row['rawOb'] ?? row['rawObs'] ?? row['message']) as String?,
        metarObsTime: _parseEpoch(row['obsTime']),
      );
    } on Exception {
      return AirportWeather(icao: icao);
    }
  }

  Future<AirportWeather> _fetchTaf(String icao) async {
    try {
      final res = await _dio.get<List<dynamic>>(
        _tafUrl,
        queryParameters: {'ids': icao, 'format': 'json'},
      );
      if (res.data == null || res.data!.isEmpty) {
        return AirportWeather(icao: icao);
      }
      final row = res.data!.first as Map<String, dynamic>;
      return AirportWeather(
        icao: icao,
        taf: (row['rawTAF'] ?? row['message']) as String?,
      );
    } on Exception {
      return AirportWeather(icao: icao);
    }
  }

  static DateTime? _parseEpoch(dynamic seconds) {
    if (seconds is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      seconds.toInt() * 1000,
      isUtc: true,
    );
  }
}

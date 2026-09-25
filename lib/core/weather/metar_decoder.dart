/// Minimal METAR/TAF decoders for the inspector's weather tabs — turns the
/// raw reports into a label/value table (the same fact-row style as the rest
/// of the inspector) plus keeps the raw text available below.
///
/// Decoding is intentionally conservative: unrecognised tokens are simply
/// left out of the table (the raw report is always shown underneath).
library;

/// One decoded fact: a localized label + display value.
class WeatherFact {
  const WeatherFact(this.label, this.value);

  final String label;
  final String value;
}

/// Decoded fields of one METAR.
class DecodedMetar {
  const DecodedMetar({
    this.time,
    this.flightRule,
    this.wind,
    this.visibility,
    this.phenomena,
    this.clouds,
    this.temperature,
    this.dewpoint,
    this.qnh,
    this.rvr,
    this.densityAltitude,
  });

  final String? time;

  /// `'VFR' | 'MVFR' | 'IFR'` — derived from visibility + ceiling.
  final String? flightRule;
  final String? wind;
  final String? visibility;
  final String? phenomena;
  final String? clouds;
  final String? temperature;
  final String? dewpoint;
  final String? qnh;

  /// Runway visual range (joined when several runways report).
  final String? rvr;

  /// Density altitude derived from station elevation + temp + QNH
  /// (`'2,340 ft / 713 m'`).
  final String? densityAltitude;

  /// Table rows — EVERY standard row is present; unset fields render as
  /// "not reported" ([WeatherTexts.notReported]).
  List<WeatherFact> facts(WeatherTexts t) => [
    WeatherFact(t.time, time ?? t.notReported),
    WeatherFact(t.flightRule, flightRule ?? t.notReported),
    WeatherFact(t.wind, wind ?? t.notReported),
    WeatherFact(t.visibility, visibility ?? t.notReported),
    if (rvr != null) WeatherFact(t.rvr, rvr!),
    WeatherFact(t.phenomena, phenomena ?? t.notReported),
    WeatherFact(t.clouds, clouds ?? t.notReported),
    WeatherFact(t.temperature, temperature ?? t.notReported),
    WeatherFact(t.dewpoint, dewpoint ?? t.notReported),
    WeatherFact(t.qnh, qnh ?? t.notReported),
    WeatherFact(t.densityAltitude, densityAltitude ?? t.notReported),
  ];
}

/// Base-group summary of one TAF.
class DecodedTaf {
  const DecodedTaf({
    this.valid,
    this.flightRule,
    this.wind,
    this.visibility,
    this.phenomena,
    this.clouds,
    this.tempLow,
    this.tempHigh,
    this.changeGroups = const [],
  });

  final String? valid;

  /// `'VFR' | 'MVFR' | 'IFR'` for the base forecast group.
  final String? flightRule;
  final String? wind;
  final String? visibility;
  final String? phenomena;
  final String? clouds;

  /// `TN…` / `TL…` minimum & maximum temperatures.
  final String? tempLow;
  final String? tempHigh;

  /// Raw FM / BECMG / TEMPO / PROB lines following the base group.
  final List<String> changeGroups;

  List<WeatherFact> facts(WeatherTexts t) => [
    WeatherFact(t.valid, valid ?? t.notReported),
    WeatherFact(t.flightRule, flightRule ?? t.notReported),
    WeatherFact(t.wind, wind ?? t.notReported),
    WeatherFact(t.visibility, visibility ?? t.notReported),
    WeatherFact(t.phenomena, phenomena ?? t.notReported),
    WeatherFact(t.clouds, clouds ?? t.notReported),
    WeatherFact(t.tempMin, tempLow ?? t.notReported),
    WeatherFact(t.tempMax, tempHigh ?? t.notReported),
  ];
}

// ── Public entry points ──────────────────────────────────────────────────────

/// [localeName] — pass `AppLocalizations.localeName`; decode text is Chinese
/// when it starts with `'zh'`, English otherwise. [elevationFt] (station
/// elevation) enables the density-altitude row when provided.
DecodedMetar decodeMetar(String raw, {
  required String localeName,
  double? elevationFt,
}) {
  final t = localeName.startsWith('zh') ? _zhTexts : _enTexts;
  // Remarks (RMK…) are auto-station data — stop decoding there.
  final rmkIndex = raw.indexOf(' RMK ');
  final body = rmkIndex == -1 ? raw : raw.substring(0, rmkIndex);
  final tokens = body.split(RegExp(r'\s+'));

  String? time;
  String? wind;
  String? vis;
  final rvr = <String>[];
  final phen = <String>[];
  final clouds = <String>[];
  String? temp;
  String? dew;
  String? qnh;
  var cavok = false;

  // Numerics for the derived rows (flight rules, density altitude).
  int? visMeters;
  int? ceilingFt;
  double? tempC;
  double? qnhHpa;

  for (final token in tokens) {
    if (token == 'CAVOK') {
      cavok = true;
      visMeters ??= 9999;
      vis ??= t.cavok;
      clouds.add(t.cavok);
      continue;
    }
    time ??= _matchTime(token, t);
    final w = _matchWind(token, t);
    if (w != null) {
      wind ??= w;
      continue;
    }
    // Wind variability rides on the wind row (e.g. 260V290).
    final wvar = _matchWindVariability(token, t);
    if (wvar != null && wind != null && !wind.contains(wvar)) {
      wind = '$wind $wvar';
      continue;
    }
    final v = _matchVisibility(
      token,
      t,
      collectMeters: (m) => visMeters ??= m,
    );
    if (v != null && vis == null && !cavok) vis = v;
    final r = _matchRvr(token, t);
    if (r != null) rvr.add(r);
    final p = _matchPhenomenon(token, t);
    if (p != null) phen.add(p);
    final c = _matchCloud(token, t);
    if (c != null) clouds.add(c);
    // Ceiling = lowest reported BKN/OVC layer base.
    final cm = _cloudRe.firstMatch(token);
    if (cm != null && (cm.group(1) == 'BKN' || cm.group(1) == 'OVC')) {
      final base = int.parse(cm.group(2)!) * 100;
      if (ceilingFt == null || base < ceilingFt) ceilingFt = base;
    }
    final td = _matchTempDew(token);
    if (td != null && temp == null) {
      temp = _formatTemp(td.$1, t);
      dew = td.$2 == null ? null : _formatTemp(td.$2!, t);
      tempC = _tempValueCelsius(td.$1);
      continue;
    }
    final q = _matchQnh(
        token, t, collectHpa: (hpa) => qnhHpa ??= hpa.toDouble());
    if (q != null && qnh == null) qnh = q;
  }

  return DecodedMetar(
    time: time,
    flightRule: _flightRule(
      cavok: cavok,
      visMeters: visMeters,
      ceilingFt: ceilingFt,
    ),
    wind: wind,
    visibility: vis,
    rvr: rvr.isEmpty ? null : rvr.join(' · '),
    phenomena: phen.isEmpty ? null : phen.join(' '),
    clouds: clouds.isEmpty ? null : clouds.join(' · '),
    temperature: temp,
    dewpoint: dew,
    qnh: qnh,
    densityAltitude: _densityAltitude(
      tempC: tempC,
      qnhHpa: qnhHpa,
      elevationFt: elevationFt,
    ),
  );
}

/// Aviation flight rules from visibility + ceiling:
/// IFR < 1000 ft ceiling or < 3 SM; MVFR < 3000 ft or < 5 SM; else VFR.
String? _flightRule({
  required bool cavok,
  required int? visMeters,
  required int? ceilingFt,
}) {
  if (cavok) return 'VFR';
  if (visMeters == null && ceilingFt == null) return null;
  const mPerSm = 1609.34;
  final visSm = visMeters == null ? 999.0 : visMeters / mPerSm;
  final ceiling = ceilingFt ?? 9999;
  if (ceiling < 1000 || visSm < 3) return 'IFR';
  if (ceiling < 3000 || visSm < 5) return 'MVFR';
  return 'VFR';
}

/// Density altitude: PA = elev + (29.92 − QNH[inHg]) × 1000,
/// DA = PA + 118.8 × (OAT − ISA@PA), ISA = 15 − 1.9812 °C per 1000 ft.
String? _densityAltitude({
  required double? tempC,
  required double? qnhHpa,
  required double? elevationFt,
}) {
  if (tempC == null || qnhHpa == null || elevationFt == null) return null;
  final qnhInHg = qnhHpa / 33.8639;
  final pressureAltFt = elevationFt + (29.92 - qnhInHg) * 1000.0;
  final isaTempC = 15.0 - 1.9812 * (pressureAltFt / 1000.0);
  final daFt = pressureAltFt + 118.8 * (tempC - isaTempC);
  String sep(int v) =>
      v.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
      );
  return '${sep(daFt.round())} ft / ${sep((daFt * 0.3048).round())} m';
}

/// Decodes a TAF's base group; everything from the first FM/BECMG/TEMPO/
/// PROB/INTER token on is kept verbatim in [DecodedTaf.changeGroups].
DecodedTaf decodeTaf(String raw, {required String localeName}) {
  final t = localeName.startsWith('zh') ? _zhTexts : _enTexts;
  final tokens = raw.split(RegExp(r'\s+'));

  final changeMarker = RegExp(r'^(FM|BECMG|TEMPO|PROB\d{2}|INTER)');
  final baseEnd = tokens.indexWhere((token) => changeMarker.hasMatch(token));
  final baseTokens = baseEnd == -1 ? tokens : tokens.sublist(0, baseEnd);

  String? valid;
  String? wind;
  String? vis;
  final phen = <String>[];
  final clouds = <String>[];
  String? tempLow;
  String? tempHigh;
  var cavok = false;
  int? visMeters;
  int? ceilingFt;

  for (final token in baseTokens) {
    valid ??= _matchValidPeriod(token, t);
    if (token == 'CAVOK') {
      cavok = true;
      visMeters ??= 9999;
      vis ??= t.cavok;
      clouds.add(t.cavok);
      continue;
    }
    // TAF temperature extremes: TN18/0922Z TL27/1507Z.
    final tn = RegExp(r'^TN(M?\d{2})/').firstMatch(token);
    if (tn != null && tempLow == null) {
      tempLow = _formatTemp(tn.group(1)!, t);
      continue;
    }
    final tl = RegExp(r'^TL(M?\d{2})/').firstMatch(token);
    if (tl != null && tempHigh == null) {
      tempHigh = _formatTemp(tl.group(1)!, t);
      continue;
    }
    wind ??= _matchWind(token, t);
    final v = _matchVisibility(token, t, collectMeters: (m) => visMeters ??= m);
    if (v != null && vis == null) vis = v;
    final p = _matchPhenomenon(token, t);
    if (p != null) phen.add(p);
    final c = _matchCloud(token, t);
    if (c != null) clouds.add(c);
    // Ceiling = lowest reported BKN/OVC layer base.
    final cm = _cloudRe.firstMatch(token);
    if (cm != null && (cm.group(1) == 'BKN' || cm.group(1) == 'OVC')) {
      final base = int.parse(cm.group(2)!) * 100;
      if (ceilingFt == null || base < ceilingFt) ceilingFt = base;
    }
  }

  final changeGroups = baseEnd == -1
      ? <String>[]
      : _splitChangeGroups(tokens.sublist(baseEnd));

  return DecodedTaf(
    valid: valid,
    flightRule: _flightRule(
      cavok: cavok,
      visMeters: visMeters,
      ceilingFt: ceilingFt,
    ),
    wind: wind,
    visibility: vis,
    phenomena: phen.isEmpty ? null : phen.join(' '),
    clouds: clouds.isEmpty ? null : clouds.join(' · '),
    tempLow: tempLow,
    tempHigh: tempHigh,
    changeGroups: changeGroups,
  );
}

/// Splits change-group tokens into lines: a marker starts a new line.
List<String> _splitChangeGroups(List<String> tokens) {
  final marker = RegExp(r'^(FM\d{6}|BECMG|TEMPO|PROB\d{2}|INTER)$');
  final lines = <String>[];
  final current = <String>[];
  for (final token in tokens) {
    if (marker.hasMatch(token) && current.isNotEmpty) {
      lines.add(current.join(' '));
      current.clear();
    }
    current.add(token);
  }
  if (current.isNotEmpty) lines.add(current.join(' '));
  return lines;
}

// ── Field matchers ───────────────────────────────────────────────────────────

final RegExp _timeRe = RegExp(r'^(\d{2})(\d{2})(\d{2})Z$');
final RegExp _windRe =
RegExp(r'^(\d{3}|VRB)(\d{2,3})(G(\d{2,3}))?(KT|MPS|KMH)$');
final RegExp _windVarRe = RegExp(r'^(\d{3})V(\d{3})$');
final RegExp _visMetersRe = RegExp(r'^(\d{4})(NDV)?$');
final RegExp _visSmRe = RegExp(r'^(P?)(\d{1,2})SM$');
final RegExp _rvrRe = RegExp(
  r'^R(\d{2}[LRC]?)/([PM])?(\d{4})(?:V([PM])?(\d{4}))?(FT)?$',
);
final RegExp _cloudRe = RegExp(r'^(FEW|SCT|BKN|OVC)(\d{3})(CB|TCU)?$');
final RegExp _tempDewRe = RegExp(r'^(M?\d{2})/(M?\d{2})?$');
final RegExp _qnhQRe = RegExp(r'^Q(\d{4})$');
final RegExp _qnhARe = RegExp(r'^A(\d{4})$');
final RegExp _validRe = RegExp(r'^(\d{2})(\d{2})/(\d{2})(\d{2})$');
final RegExp _phenomRe = RegExp(
  r'^(RE)?(VC|[+-])?(TS|SH|FZ|BL|DR)?'
  r'(DZ|RA|SN|SG|IC|PL|GR|GS|UP|SH|BR|FG|FU|VA|DU|SA|HZ|PO|SQ|FC|SS|DS)$',
);

String? _matchTime(String token, WeatherTexts t) {
  final m = _timeRe.firstMatch(token);
  if (m == null) return null;
  return t.dayTime(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
  );
}

String? _matchWind(String token, WeatherTexts t) {
  final m = _windRe.firstMatch(token);
  if (m == null) return null;
  final dir = m.group(1)!;
  final speed = int.parse(m.group(2)!);
  final gust = m.group(4) == null ? null : int.parse(m.group(4)!);
  final unit = m.group(5)!;
  final dirText = dir == 'VRB' ? t.vrb : '$dir°';
  final unitText = switch (unit) {
    'MPS' => ' m/s',
    'KMH' => ' km/h',
    _ => ' kt',
  };
  if (speed == 0 && dir == '000') return t.calm;
  final speedText = '$speed$unitText';
  return gust == null
      ? '$dirText $speedText'
      : '$dirText $speedText ${t.gust(gust)}$unitText';
}

/// `260V290` — wind direction varying between the two bearings.
String? _matchWindVariability(String token, WeatherTexts t) {
  final m = _windVarRe.firstMatch(token);
  if (m == null) return null;
  return t.windVariable(m.group(1)!, m.group(2)!);
}

/// `R16L/1200V1800FT` → `16L 1200–1800 m`.
String? _matchRvr(String token, WeatherTexts t) {
  final m = _rvrRe.firstMatch(token);
  if (m == null) return null;
  final runway = m.group(1)!;
  String value(String? prefix, String? meters) {
    if (meters == null) return '';
    final v = int.parse(meters);
    if (prefix == 'P') return t.rvrAbove(v);
    if (prefix == 'M') return t.rvrBelow(v);
    return '$v';
  }

  const unit = ' m';
  final low = value(m.group(2), m.group(3));
  final high = m.group(5) == null ? null : value(m.group(4), m.group(5));
  return high == null ? '$runway $low$unit' : '$runway $low–$high$unit';
}

String? _matchVisibility(String token,
    WeatherTexts t, {
      void Function(int meters)? collectMeters,
    }) {
  final meters = _visMetersRe.firstMatch(token);
  if (meters != null) {
    final v = int.parse(meters.group(1)!);
    collectMeters?.call(v);
    return v >= 9999 ? t.visibility10kmPlus : t.visibilityMeters(v);
  }
  final sm = _visSmRe.firstMatch(token);
  if (sm != null) {
    final v = int.parse(sm.group(2)!);
    collectMeters?.call((v * 1609.34).round());
    return sm.group(1) == 'P' ? t.visibilitySmPlus(v) : t.visibilitySm(v);
  }
  return null;
}

String? _matchPhenomenon(String token, WeatherTexts t) {
  // Lone 'TS' = thunderstorm without reported precipitation.
  if (token == 'TS') return t.descriptor('TS');
  // 'NSW' = no significant weather.
  if (token == 'NSW') return t.noSignificantWeather;
  final m = _phenomRe.firstMatch(token);
  if (m == null) return null;
  final recent = m.group(1) == 'RE';
  final intensity = m.group(2) ?? '';
  final descriptor = m.group(3);
  final substance = m.group(4)!;
  final parts = <String>[
    if (recent) t.recent,
    if (intensity == '-') t.light,
    if (intensity == '+') t.heavy,
    if (intensity == 'VC') t.vicinity,
    if (descriptor != null) t.descriptor(descriptor),
    t.substance(substance),
  ];
  return parts.join();
}

String? _matchCloud(String token, WeatherTexts t) {
  if (token == 'NSC' || token == 'NCD' || token == 'SKC' || token == 'CLR') {
    return t.noSignificantCloud;
  }
  final m = _cloudRe.firstMatch(token);
  if (m == null) return null;
  final amount = t.cloudAmount(m.group(1)!);
  final baseFt = int.parse(m.group(2)!) * 100;
  final convective = m.group(3) == 'CB'
      ? ' ${t.cumulonimbus}'
      : m.group(3) == 'TCU'
      ? ' ${t.toweringCumulus}'
      : '';
  return '$amount ${t.cloudBaseFt(baseFt)}$convective';
}

(String, String?)? _matchTempDew(String token) {
  final m = _tempDewRe.firstMatch(token);
  if (m == null) return null;
  return (m.group(1)!, m.group(2));
}

String _formatTemp(String code, WeatherTexts t) {
  final minus = code.startsWith('M');
  final value = int.parse(minus ? code.substring(1) : code);
  return minus ? t.negativeTemp(value) : '$value ${t.celsius}';
}

String? _matchQnh(String token,
    WeatherTexts t, {
      void Function(int hPa)? collectHpa,
    }) {
  final q = _qnhQRe.firstMatch(token);
  if (q != null) {
    final hpa = int.parse(q.group(1)!);
    collectHpa?.call(hpa);
    return t.qnhHpa(hpa);
  }
  final a = _qnhARe.firstMatch(token);
  if (a != null) {
    final inHg = int.parse(a.group(1)!) / 100.0;
    collectHpa?.call((inHg * 33.8639).round());
    return t.qnhInHg(inHg);
  }
  return null;
}

/// `M12` → `-12.0` — celsius value for density-altitude computation.
double _tempValueCelsius(String code) {
  final minus = code.startsWith('M');
  final v = int.parse(minus ? code.substring(1) : code).toDouble();
  return minus ? -v : v;
}

String? _matchValidPeriod(String token, WeatherTexts t) {
  final m = _validRe.firstMatch(token);
  if (m == null) return null;
  return t.validPeriod(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
    int.parse(m.group(4)!),
  );
}

// ── Localized texts ──────────────────────────────────────────────────────────

abstract class WeatherTexts {
  const WeatherTexts();

  String get time;

  String get wind;

  String get visibility;

  String get phenomena;

  String get clouds;

  String get temperature;

  String get dewpoint;

  String get qnh;

  String get flightRule;

  String get densityAltitude;

  String get notReported;

  String get valid;

  String get rvr;

  String get noSignificantWeather;

  String get tempMin;

  String get tempMax;

  String get recent;

  String get calm;

  String get vrb;

  String get cavok;

  String get light;

  String get heavy;

  String get vicinity;

  String get noSignificantCloud;

  String get cumulonimbus;

  String get toweringCumulus;

  String get celsius;

  String get visibility10kmPlus;

  String dayTime(int day, int hour, int minute);

  String windSpeed(int kt);

  String gust(int kt);

  String windVariable(String from, String to);

  String visibilityMeters(int m);

  String visibilitySm(int sm);

  String visibilitySmPlus(int sm);

  String cloudAmount(String code);

  String cloudBaseFt(int ft);

  String negativeTemp(int c);

  String qnhHpa(int hpa);

  String qnhInHg(double inHg);

  String validPeriod(int d1, int h1, int d2, int h2);

  String rvrAbove(int m);

  String rvrBelow(int m);

  String descriptor(String code);

  String substance(String code);
}

class _Zh extends WeatherTexts {
  const _Zh();

  @override
  String get time => '时间';

  @override
  String get wind => '风';

  @override
  String get visibility => '能见度';

  @override
  String get phenomena => '天气现象';

  @override
  String get clouds => '云';

  @override
  String get temperature => '温度';

  @override
  String get dewpoint => '露点';

  @override
  String get qnh => '修正海压';

  @override
  String get valid => '有效时段';

  @override
  String get flightRule => '飞行规则';

  @override
  String get densityAltitude => '密度高度';

  @override
  String get notReported => '未回报';

  @override
  String get rvr => '跑道视程';

  @override
  String get tempMin => '最低气温';

  @override
  String get tempMax => '最高气温';

  @override
  String get recent => '近期';

  @override
  String get noSignificantWeather => '无重要天气';

  @override
  String get calm => '静风';

  @override
  String get vrb => '风向不定';

  @override
  String get cavok => 'CAVOK（机场飞行规则良好，无重要云）';

  @override
  String get light => '小';

  @override
  String get heavy => '大';

  @override
  String get vicinity => '附近';

  @override
  String get noSignificantCloud => '无重要云';

  @override
  String get cumulonimbus => '积雨云';

  @override
  String get toweringCumulus => '浓积云';

  @override
  String get celsius => '°C';

  @override
  String get visibility10kmPlus => '≥10 km';

  @override
  String dayTime(int day, int hour, int minute) =>
      '$day日 ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} UTC';

  @override
  String windSpeed(int kt) => '$kt kt';

  @override
  String gust(int kt) => '阵风 $kt kt';

  @override
  String windVariable(String from, String to) => '风向 $from°–$to° 变化';

  @override
  String visibilityMeters(int m) => '$m m';

  @override
  String visibilitySm(int sm) => '$sm SM';

  @override
  String visibilitySmPlus(int sm) => '≥$sm SM';

  @override
  String cloudAmount(String code) => switch (code) {
    'FEW' => '少云',
    'SCT' => '疏云',
    'BKN' => '多云',
    'OVC' => '阴天',
    _ => code,
  };

  @override
  String cloudBaseFt(int ft) =>
      '云底 ${ft.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ft';

  @override
  String negativeTemp(int c) => '-$c °C';

  @override
  String qnhHpa(int hpa) => '$hpa hPa';

  @override
  String qnhInHg(double inHg) => '$inHg inHg';

  @override
  String validPeriod(int d1, int h1, int d2, int h2) =>
      '$d1日 ${h1.toString().padLeft(2, '0')}:00 – $d2日 ${h2.toString().padLeft(2, '0')}:00 UTC';

  @override
  String rvrAbove(int m) => '≥$m';

  @override
  String rvrBelow(int m) => '≤$m';

  @override
  String descriptor(String code) => switch (code) {
    'TS' => '雷暴',
    'SH' => '阵性',
    'FZ' => '冻结',
    'BL' => '吹扬',
    'DR' => '低吹',
    _ => code,
  };

  @override
  String substance(String code) => switch (code) {
    'DZ' => '毛毛雨',
    'RA' => '雨',
    'SN' => '雪',
    'SG' => '雪粒',
    'IC' => '冰针',
    'PL' => '冰粒',
    'GR' => '冰雹',
    'GS' => '霰',
    'UP' => '未知降水',
    'SH' => '阵雨',
    'BR' => '轻雾',
    'FG' => '雾',
    'FU' => '烟',
    'VA' => '火山灰',
    'DU' => '浮尘',
    'SA' => '扬沙',
    'HZ' => '霾',
    'PO' => '尘卷风',
    'SQ' => '飑',
    'FC' => '龙卷',
    'SS' => '沙暴',
    'DS' => '尘暴',
    _ => code,
  };
}

class _En extends WeatherTexts {
  const _En();

  @override
  String get time => 'Time';

  @override
  String get wind => 'Wind';

  @override
  String get visibility => 'Visibility';

  @override
  String get phenomena => 'Weather';

  @override
  String get clouds => 'Clouds';

  @override
  String get temperature => 'Temperature';

  @override
  String get dewpoint => 'Dew point';

  @override
  String get qnh => 'QNH';

  @override
  String get valid => 'Valid';

  @override
  String get flightRule => 'Flight rules';

  @override
  String get densityAltitude => 'Density altitude';

  @override
  String get notReported => 'Not reported';

  @override
  String get rvr => 'RVR';

  @override
  String get tempMin => 'Min temp';

  @override
  String get tempMax => 'Max temp';

  @override
  String get recent => 'Recent';

  @override
  String get noSignificantWeather => 'No significant weather';

  @override
  String get calm => 'Calm';

  @override
  String get vrb => 'VRB';

  @override
  String get cavok => 'CAVOK';

  @override
  String get light => 'Light';

  @override
  String get heavy => 'Heavy';

  @override
  String get vicinity => 'Vicinity';

  @override
  String get noSignificantCloud => 'No significant cloud';

  @override
  String get cumulonimbus => 'CB';

  @override
  String get toweringCumulus => 'TCU';

  @override
  String get celsius => '°C';

  @override
  String get visibility10kmPlus => '≥10 km';

  @override
  String dayTime(int day, int hour, int minute) =>
      'Day $day, ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} UTC';

  @override
  String windSpeed(int kt) => '$kt kt';

  @override
  String gust(int kt) => 'G$kt kt';

  @override
  String windVariable(String from, String to) => 'varying $from–$to°';

  @override
  String visibilityMeters(int m) => '$m m';

  @override
  String visibilitySm(int sm) => '$sm SM';

  @override
  String visibilitySmPlus(int sm) => '≥$sm SM';

  @override
  String cloudAmount(String code) => switch (code) {
    'FEW' => 'Few',
    'SCT' => 'Scattered',
    'BKN' => 'Broken',
    'OVC' => 'Overcast',
    _ => code,
  };

  @override
  String cloudBaseFt(int ft) =>
      'base ${ft.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ft';

  @override
  String negativeTemp(int c) => '-$c °C';

  @override
  String qnhHpa(int hpa) => '$hpa hPa';

  @override
  String qnhInHg(double inHg) => '$inHg inHg';

  @override
  String validPeriod(int d1, int h1, int d2, int h2) =>
      'Day $d1 ${h1.toString().padLeft(2, '0')}:00 – Day $d2 ${h2.toString().padLeft(2, '0')}:00 UTC';

  @override
  String rvrAbove(int m) => '≥$m';

  @override
  String rvrBelow(int m) => '≤$m';

  @override
  String descriptor(String code) => switch (code) {
    'TS' => 'Thunderstorm',
    'SH' => 'Shower',
    'FZ' => 'Freezing',
    'BL' => 'Blowing',
    'DR' => 'Drifting',
    _ => code,
  };

  @override
  String substance(String code) => switch (code) {
    'DZ' => 'drizzle',
    'RA' => 'rain',
    'SN' => 'snow',
    'SG' => 'snow grains',
    'IC' => 'ice crystals',
    'PL' => 'ice pellets',
    'GR' => 'hail',
    'GS' => 'small hail',
    'UP' => 'unknown precipitation',
    'SH' => 'showers',
    'BR' => 'mist',
    'FG' => 'fog',
    'FU' => 'smoke',
    'VA' => 'volcanic ash',
    'DU' => 'dust',
    'SA' => 'sand',
    'HZ' => 'haze',
    'PO' => 'dust whirls',
    'SQ' => 'squall',
    'FC' => 'funnel cloud',
    'SS' => 'sandstorm',
    'DS' => 'duststorm',
    _ => code,
  };
}

const _zhTexts = _Zh();
const _enTexts = _En();

/// Returns the localized weather text set for [localeName] (from
/// `AppLocalizations.localeName`), so UI tables share the decoder's wording.
WeatherTexts weatherTextsFor(String localeName) =>
    localeName.startsWith('zh') ? _zhTexts : _enTexts;

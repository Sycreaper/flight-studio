// Weather decoder + sunrise/sunset unit tests backing the inspector's
// METAR / TAF tabs and the airport overview's "sunrise & sunset" row.

import 'package:flight_studio/core/geo/sun_times.dart';
import 'package:flight_studio/core/weather/metar_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decodeMetar', () {
    test('decodes a full report into a Chinese fact table', () {
      final decoded = decodeMetar(
        'METAR KSEA 200853Z 00000KT 7SM FEW200 12/11 A3009 RMK AO2 SLP197',
        localeName: 'zh',
      );

      final facts = {
        for (final f in decoded.facts(weatherTextsFor('zh'))) f.label: f.value,
      };
      expect(facts['时间'], '20日 08:53 UTC');
      expect(facts['风'], '静风');
      expect(facts['能见度'], '7 SM');
      expect(facts['云'], contains('少云'));
      expect(facts['温度'], '12 °C');
      expect(facts['露点'], '11 °C');
      expect(facts['修正海压'], '30.09 inHg');
    });

    test('decodes wind, phenomena and metric QNH (zh)', () {
      final decoded = decodeMetar(
        'METAR ZBAA 201200Z 36018G30KT 9999 -TSRA BKN012 OVC030 18/09 Q1013',
        localeName: 'zh',
      );

      final facts = {
        for (final f in decoded.facts(weatherTextsFor('zh'))) f.label: f.value,
      };
      expect(facts['风'], contains('360°'));
      expect(facts['风'], contains('阵风 30 kt'));
      expect(facts['能见度'], '≥10 km');
      expect(facts['天气现象'], contains('雷暴'));
      expect(facts['天气现象'], contains('小'));
      expect(facts['天气现象'], contains('雨'));
      expect(facts['云'], contains('多云'));
      expect(facts['云'], contains('阴天'));
      expect(facts['修正海压'], '1013 hPa');
    });

    test('English output + CAVOK handling', () {
      final decoded = decodeMetar(
        'METAR EDDF 200950Z 27010KT CAVOK 22/10 Q1022',
        localeName: 'en',
      );

      final facts = {
        for (final f in decoded.facts(weatherTextsFor('en'))) f.label: f.value,
      };
      expect(facts['Visibility'], 'CAVOK');
      expect(facts['Clouds'], 'CAVOK');
      expect(facts['QNH'], '1022 hPa');
    });

    test('decodes wind variability, RVR, lone TS and stops at RMK', () {
      final decoded = decodeMetar(
        'METAR ZSPD 201100Z 12008KT 260V290 9999 R16L/1200V1800FT '
        'TS -SHRA BKN030TCU 24/21 Q1005 NOSIG RMK NOTHING HERE',
        localeName: 'zh',
      );

      final facts = {
        for (final f in decoded.facts(weatherTextsFor('zh'))) f.label: f.value,
      };
      // Wind row carries the variability range.
      expect(facts['风'], contains('120°'));
      expect(facts['风'], contains('260°–290°'));
      // RVR row (the 4-digit-only tail after V is ignored, 'N' too).
      expect(facts['跑道视程'], contains('16L'));
      expect(facts['跑道视程'], contains('1200'));
      // Lone TS decodes as thunderstorm; -SHRA as light rain showers.
      expect(facts['天气现象'], contains('雷暴'));
      expect(facts['天气现象'], contains('小'));
      expect(facts['天气现象'], contains('阵性'));
      expect(facts['天气现象'], contains('雨'));
      // TCU cloud suffix decodes.
      expect(facts['云'], contains('浓积云'));
      // RMK content must not leak into any decoded row.
      expect(facts.values.any((v) => v.contains('NOTHING')), isFalse);
    });

    test('MPS wind units (Chinese stations) and NSW decode', () {
      final decoded = decodeMetar(
        'METAR ZSQD 201130Z 13005MPS 9999 NSW 17/14 Q1010',
        localeName: 'zh',
      );

      final facts = {
        for (final f in decoded.facts(weatherTextsFor('zh'))) f.label: f.value
      };
      expect(facts['风'], contains('130°'));
      expect(facts['风'], contains('5 m/s'));
      expect(facts['天气现象'], '无重要天气');
      // Sanity: QNH + flight rules still derive.
      expect(facts['修正海压'], '1010 hPa');
      expect(facts['飞行规则'], 'VFR');
    });

    test('KMH wind units decode', () {
      final decoded = decodeMetar(
        'METAR UAAA 201100Z 27012G18KMH 9999 SKC 20/08 Q1023',
        localeName: 'en',
      );
      expect(decoded.wind, contains('12 km/h'));
      expect(decoded.wind, contains('G18'));
    });

    test('TAF temperature extremes (TN/TL) decode', () {
      final decoded = decodeTaf(
        'TAF ZBAA 200800Z 2009/2112 32008KT 9999 FEW030 TN16/2020Z TL29/2107Z',
        localeName: 'zh',
      );

      final facts = {
        for (final f in decoded.facts(weatherTextsFor('zh'))) f.label: f.value
      };
      expect(facts['最低气温'], '16 °C');
      expect(facts['最高气温'], '29 °C');
    });

    test('TAF decodes with the same detail as METAR (all rows + flight '
        'rules)', () {
      final decoded = decodeTaf(
        'TAF KSEA 200856Z 2009/2112 00000KT P6SM BKN015 '
            'FM201300 00000KT 6SM BR OVC002 '
            'TEMPO 2015/2017 36004KT 2SM -RA',
        localeName: 'en',
      );

      final facts = {
        for (final f in decoded.facts(weatherTextsFor('en'))) f.label: f.value
      };
      // Every standard row present.
      for (final expected in [
        'Valid',
        'Flight rules',
        'Wind',
        'Visibility',
        'Weather',
        'Clouds',
        'Min temp',
        'Max temp',
      ]) {
        expect(facts.keys, contains(expected), reason: 'missing: $expected');
      }
      // Base-group flight rule: BKN015 + ≥5 SM → MVFR.
      expect(facts['Flight rules'], 'MVFR');
      expect(facts['Clouds'], contains('Broken'));
      // Missing TN/TL rows fall back to Not reported.
      expect(facts['Min temp'], 'Not reported');
      // Change groups stay raw.
      expect(decoded.changeGroups, hasLength(2));
    });

    test('flight rules: VFR / MVFR / IFR from ceiling + visibility', () {
      // CAVOK → VFR.
      expect(
        decodeMetar('METAR KSEA 200853Z 00000KT CAVOK 12/11 A3009',
            localeName: 'en').flightRule,
        'VFR',
      );
      // FEW200 + 7SM → VFR (FEW is not a ceiling).
      expect(
        decodeMetar(
          'METAR KSEA 200853Z 00000KT 7SM FEW200 12/11 A3009',
          localeName: 'en',
        ).flightRule,
        'VFR',
      );
      // BKN012 (1200 ft) + 9999 → MVFR.
      expect(
        decodeMetar(
          'METAR KSEA 200853Z 00000KT 9999 BKN012 OVC030 12/11 A3009',
          localeName: 'en',
        ).flightRule,
        'MVFR',
      );
      // BKN008 (800 ft) → IFR regardless of visibility.
      expect(
        decodeMetar(
          'METAR KSEA 200853Z 00000KT 9999 BKN008 12/11 A3009',
          localeName: 'en',
        ).flightRule,
        'IFR',
      );
      // 2 SM visibility with no ceiling → IFR.
      expect(
        decodeMetar(
          'METAR KSEA 200853Z 00000KT 2SM BR 12/11 A3009',
          localeName: 'en',
        ).flightRule,
        'IFR',
      );
      // No visibility and no clouds → not reported.
      expect(
        decodeMetar('METAR KSEA 200853Z 00000KT 12/11 A3009',
            localeName: 'en').flightRule,
        isNull,
      );
    });

    test('density altitude computes from elevation + temp + QNH', () {
      // KSEA: elev 433 ft, 12 °C, QNH 30.09 inHg (≈1019 hPa).
      final decoded = decodeMetar(
        'METAR KSEA 200853Z 00000KT 7SM FEW200 12/11 A3009',
        localeName: 'en',
        elevationFt: 433,
      );
      // PA = 433 + (29.92 − 30.09) × 1000 ≈ 263 ft; ISA ≈ 14.5 °C;
      // DA ≈ 263 + 118.8 × (12 − 14.5) ≈ −34 ft → around sea level.
      expect(decoded.densityAltitude, isNotNull);
      final ft = int.parse(
          decoded.densityAltitude!.split(' ft').first.replaceAll(',', ''));
      expect(ft, inInclusiveRange(-700, 700));
    });

    test('every standard row is present; missing values say not reported',
            () {
          final decoded = decodeMetar(
            'METAR KSEA 200853Z 00000KT',
            localeName: 'en',
          );
          final facts = decoded.facts(weatherTextsFor('en'));
          final labels = facts.map((f) => f.label).toList();
          for (final expected in [
            'Time',
            'Flight rules',
            'Wind',
            'Visibility',
            'Weather',
            'Clouds',
            'Temperature',
            'Dew point',
            'QNH',
            'Density altitude',
          ]) {
            expect(
                labels, contains(expected), reason: 'missing row: $expected');
          }
          final byLabel = {for (final f in facts) f.label: f.value};
          expect(byLabel['Visibility'], 'Not reported');
          expect(byLabel['Clouds'], 'Not reported');
          expect(byLabel['QNH'], 'Not reported');
        });
  });

  group('decodeTaf', () {
    test('base group decoded, change groups kept raw', () {
      final decoded = decodeTaf(
        'TAF KSEA 200856Z 2009/2112 00000KT P6SM FEW200 '
        'FM201300 00000KT 6SM BR OVC002 '
        'TEMPO 2015/2017 36004KT 2SM -RA',
        localeName: 'zh',
      );

      final facts = {
        for (final f in decoded.facts(weatherTextsFor('zh'))) f.label: f.value,
      };
      expect(facts['有效时段'], '20日 09:00 – 21日 12:00 UTC');
      expect(facts['风'], '静风');
      expect(facts['能见度'], '≥6 SM');
      // Change groups verbatim.
      expect(decoded.changeGroups, hasLength(2));
      expect(decoded.changeGroups.first, startsWith('FM201300'));
      expect(decoded.changeGroups.last, startsWith('TEMPO'));
    });
  });

  group('computeSunTimes', () {
    test('KSEA in September: sunrise ~13:50Z, sunset ~02:10Z next day', () {
      final sun = computeSunTimes(47.45, -122.31, DateTime.utc(2026, 9, 20));
      expect(sun.sunrise, isNotNull);
      expect(sun.sunset, isNotNull);
      // Seattle sunrise ~06:50 PDT = 13:50 UTC.
      expect(sun.sunrise!.hour, inInclusiveRange(13, 14));
      // Sunset ~19:10 PDT = 02:10 UTC on the FOLLOWING UTC day.
      expect(sun.sunset!.day, 21);
      expect(sun.sunset!.hour, inInclusiveRange(1, 3));
      // Day length is a sane ~12.3 hours in late September.
      final length = sun.sunset!.difference(sun.sunrise!);
      expect(length.inMinutes, inInclusiveRange(700, 780));
    });

    test('polar night returns empty (Tromsø in December)', () {
      final sun = computeSunTimes(69.65, 18.96, DateTime.utc(2026, 12, 20));
      expect(sun.isEmpty, isTrue);
    });
  });
}

// Match the decoder's Chinese/English label sets for table assertions above.

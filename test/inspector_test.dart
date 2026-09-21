// Inspector drawer tests: the LNM-style information dock fed by
// InspectorService — double-click on a map marker or search result inspects
// a point; airports additionally pull runway facts from the navdata DB.

import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flight_studio/core/navdata/navdata_types.dart';
import 'package:flight_studio/core/parsing/apt_dat_parser.dart';
import 'package:flight_studio/data/db/database.dart';
import 'package:flight_studio/data/navdata/airport_details.dart';
import 'package:flight_studio/data/navdata/importer.dart';
import 'package:flight_studio/data/navdata/navdata_service.dart';
import 'package:flight_studio/data/navdata/ourairports_enricher.dart';
import 'package:flight_studio/l10n/app_localizations.dart';
import 'package:flight_studio/ui/map/nav_markers.dart';
import 'package:flight_studio/ui/panels/inspector_panel.dart';
import 'package:flight_studio/ui/panels/inspector_service.dart';
import 'package:flight_studio/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

const _waypoint = NavPoint(
  category: NavPointCategory.waypoint,
  ident: 'BIBAX',
  name: 'BIBAX',
  latitude: 47.5,
  longitude: -122.3,
);

const _vor = NavPoint(
  category: NavPointCategory.vordme,
  ident: 'SEA',
  name: 'Seattle VOR/DME',
  latitude: 47.43,
  longitude: -122.31,
  frequency: '116.80',
);

NavPoint _airport() => const NavPoint(
  category: NavPointCategory.airport,
  ident: 'KSEA',
  name: 'Seattle-Tacoma Intl',
  latitude: 47.45,
  longitude: -122.31,
  elevationFt: 433,
);

Future<void> _pumpPanel(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: InspectorPanel()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    InspectorService.instance.clear();
  });

  testWidgets('shows hint when nothing is inspected', (tester) async {
    await _pumpPanel(tester);
    expect(find.textContaining('Double-click'), findsOneWidget);
  });

  testWidgets('waypoint fact sheet: type + DMS coordinates, no actions '
      'crash without callbacks', (tester) async {
    await _pumpPanel(tester);
    InspectorService.instance.inspect(_waypoint);
    await tester.pumpAndSettle();

    // Ident + name are both 'BIBAX' for a waypoint → two matches.
    expect(find.text('BIBAX'), findsWidgets);
    expect(find.text('Waypoint'), findsOneWidget);
    // DMS coordinates rendered.
    expect(find.textContaining('N47'), findsOneWidget);
    expect(find.textContaining('W122'), findsOneWidget);
  });

  testWidgets('airport overview tab: elevation shown, runway query is '
      'safe without an open DB', (tester) async {
    await _pumpPanel(tester);
    InspectorService.instance.inspect(_airport());
    await tester.pumpAndSettle();

    // Header ident + ICAO fact row both read 'KSEA'.
    expect(find.text('KSEA'), findsWidgets);
    expect(find.text('ICAO'), findsOneWidget);
    expect(find.text('433 ft / 132 m'), findsOneWidget);
  });

  testWidgets('VOR fact sheet shows the frequency', (tester) async {
    await _pumpPanel(tester);
    InspectorService.instance.inspect(_vor);
    await tester.pumpAndSettle();

    expect(find.text('SEA'), findsOneWidget);
    expect(find.text('Frequency'), findsOneWidget);
    expect(find.text('116.80'), findsOneWidget);
  });

  testWidgets('clear button returns to the hint', (tester) async {
    await _pumpPanel(tester);
    InspectorService.instance.inspect(_waypoint);
    await tester.pumpAndSettle();
    expect(find.text('BIBAX'), findsWidgets);

    await tester.tap(find.byTooltip('Clear inspector'));
    await tester.pumpAndSettle();
    expect(find.text('BIBAX'), findsNothing);
    expect(find.textContaining('Double-click'), findsOneWidget);
  });

  testWidgets('marker double-tap inspects the point', (tester) async {
    NavPoint? inspected;
    // Marker sits at the initial map centre so it renders on-screen.
    const markerPoint = NavPoint(
      category: NavPointCategory.vordme,
      ident: 'SEA',
      name: 'Test VOR/DME',
      latitude: 35.0,
      longitude: 0.0,
      frequency: '116.80',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => SizedBox(
              width: 400,
              height: 300,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(35.0, 0.0),
                  initialZoom: 8,
                ),
                children: [
                  buildNavMarkerLayer(
                    ctx,
                    [markerPoint],
                    NavPointCategory.values.toSet(),
                    onInspect: (p) => inspected = p,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Two quick taps on the marker (double-click).
    await tester.tap(find.byType(SvgPicture).first);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(find.byType(SvgPicture).first);
    await tester.pumpAndSettle();

    expect(inspected, isNotNull);
    expect(inspected!.ident, 'SEA');
  });

  test('queryAirportDetails returns runways from the navdata DB', () async {
    final db = NavdataDatabase(NativeDatabase.memory());
    final importer = NavdataImporter();
    importer.attachForTest = db;
    addTearDown(db.close);

    // Seed airport + two runways directly.
    await db
        .into(db.airports)
        .insert(
          AirportsCompanion.insert(
            icao: 'KSEA',
            name: 'Seattle-Tacoma Intl',
            latitude: 47.45,
            longitude: -122.31,
            type: 'airport',
            source: 'xplane',
            iata: const drift.Value('SEA'),
            city: const drift.Value('Seattle'),
            country: const drift.Value('United States'),
            elevationFt: const drift.Value(433.0),
          ),
        );
    for (final (ident, heading, len, width) in const [
      ('16L', 158.0, 11901.0, 150.0),
      ('34R', 338.0, 9426.0, 150.0),
    ]) {
      await db
          .into(db.runways)
          .insert(
            RunwaysCompanion.insert(
              airportIcao: 'KSEA',
              ident: ident,
              latitude: 47.45,
              longitude: -122.31,
              lengthFt: len,
              headingDeg: heading,
              widthFt: drift.Value(width),
              surface: const drift.Value('asphalt'),
            ),
          );
    }

    final details = await importer.queryAirportDetails('KSEA');
    expect(details, isNotNull);
    expect(details!.iata, 'SEA');
    expect(details.runways.length, 2);
    expect(details.runways.first.ident, '16L');
    expect(details.runways.first.surface, 'asphalt');
    expect(details.runwayStripCount, 1);
    expect(details.longestRunway?.lengthFt, 11901);
    expect(await importer.queryAirportDetails('XXXX'), isNull);
  });

  test('OurAirports enrichment fills iata/city/country', () async {
    final db = NavdataDatabase(NativeDatabase.memory());
    final importer = NavdataImporter();
    importer.attachForTest = db;
    addTearDown(db.close);

    await db
        .into(db.airports)
        .insert(
          AirportsCompanion.insert(
            icao: 'ZSQD',
            name: 'Qingdao Jiaodong Intl',
            latitude: 36.36,
            longitude: 120.37,
            type: 'airport',
            source: 'xplane',
          ),
        );

    const csv =
        'id,ident,type,name,latitude_deg,longitude_deg,'
        'elevation_ft,continent,iso_country,iso_region,municipality,'
        'scheduled_service,gps_code,iata_code,local_code,home_link,'
        'wikipedia_link,keywords\n'
        '1,ZSQD,large_airport,"Qingdao Jiaodong International Airport",'
        '36.36,120.37,32,AS,CN,CN-SD,"Qingdao",yes,ZSQD,TAO,,,"",\n'
        '2,ZXXX,closed,Abandoned,0,0,0,AS,CN,CN-SD,Nowhere,no,ZXXX,,,,"",\n';

    await OurAirportsEnricher.instance.enrich(
      db,
      supportDir: () async => Directory.systemTemp,
      csvTextOverride: csv,
    );

    final row = await (db.select(
      db.airports,
    )..where((t) => t.icao.equals('ZSQD'))).getSingle();
    expect(row.iata, 'TAO');
    expect(row.city, 'Qingdao');
    expect(row.country, 'CN');
  });

  test('apt.dat rows 50–56 import ATC frequencies', () async {
    final db = NavdataDatabase(NativeDatabase.memory());
    final importer = NavdataImporter();
    importer.attachForTest = db;
    addTearDown(db.close);

    final tmp = Directory.systemTemp.createTempSync('freq_test');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final file = File('${tmp.path}/apt.dat')
      ..writeAsStringSync(
        [
          'I',
          '1300 Generated by Scenery Engine.',
          '1 433 0 0 KSEA Seattle-Tacoma Intl',
          '102 47.45 -122.31',
          '50 118650 ATIS',
          '52 121900 GND',
          '53 119500 TOWER',
          '55 125600 APPROACH',
          '99',
        ].join('\n'),
      );

    final count = await importAptDat(file, db);
    expect(count, 1);

    final details = await importer.queryAirportDetails('KSEA');
    expect(details, isNotNull);
    final freqs = details!.frequencies;
    expect(freqs.length, 4);
    expect(
      freqs.map((f) => f.type),
      containsAll(['ATIS', 'GND', 'TWR', 'APP']),
    );
    final twr = freqs.firstWhere((f) => f.type == 'TWR');
    expect(twr.frequencyKhz, 119500);
    expect(twr.mhz, '119.50');
    expect(twr.description, 'TOWER');
  });

  test('FrequencyDetails.mhz formats kHz to trimmed MHz', () {
    const cases = {
      119500: '119.50',
      121900: '121.90',
      121500: '121.50',
      118100: '118.10',
    };
    for (final entry in cases.entries) {
      expect(
        FrequencyDetails(type: 'TWR', frequencyKhz: entry.key).mhz,
        entry.value,
        reason: '${entry.key} kHz',
      );
    }
  });

  test('NavdataService delegates gracefully with no open database', () async {
    // No import has ever run in this process — must return null, not throw.
    expect(await NavdataService.instance.queryAirportDetails('KSEA'), isNull);
  });

  // Sanity: the point model used by search-result tiles is inspectable too.
  test(
    'inspecting an airport exposes runways via AirportDetails model',
    () async {
      const details = AirportDetails(
        icao: 'KSEA',
        name: 'Seattle-Tacoma Intl',
        latitude: 47.45,
        longitude: -122.31,
        type: 'airport',
        source: 'xplane',
        runways: [
          RunwayDetails(
            ident: '16L',
            headingDeg: 158,
            lengthFt: 11901,
            widthFt: 150,
          ),
        ],
      );
      expect(details.runways.single.ident, '16L');
    },
  );
}

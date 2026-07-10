// Widget tests for the Flight Studio welcome screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flight_studio/app.dart';
import 'package:flight_studio/features/flights/flight_record.dart';
import 'package:flight_studio/features/flights/flight_repository.dart';

void main() {
  testWidgets('Welcome empty state shows create CTA', (tester) async {
    await _pumpWelcome(tester, repository: FlightRepository());
    expect(find.text('Create your first flight'), findsOneWidget);
    expect(find.text('Create Flight'), findsOneWidget);
    expect(find.text('World Map'), findsOneWidget);
    expect(find.text('Flight Academy'), findsOneWidget);
  });

  testWidgets('Welcome populated state shows flight cards', (tester) async {
    final repo = FlightRepository()
      ..seed([
        FlightRecord(
          id: '1',
          departure: 'KSEA',
          arrival: 'KSFO',
          aircraftName: 'Cessna 172',
          airlineName: '',
          cruiseAltitudeFt: 35000,
          durationMinutes: 142,
        ),
      ]);
    await _pumpWelcome(tester, repository: repo);
    expect(find.text('KSEA \u2192 KSFO'), findsOneWidget);
    expect(find.text('Create your first flight'), findsNothing);
  });

  testWidgets('Nav drawer switches to settings page', (tester) async {
    await _pumpWelcome(tester, repository: FlightRepository());
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
  });
}

Future<void> _pumpWelcome(WidgetTester tester,
    {required FlightRepository repository}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(FlightStudioApp(repository: repository));
  await tester.pumpAndSettle();
}

// Regression test: typing in the welcome prompt box must not drop focus.
//
// The prompt box used to swap its child tree (Row ↔ Column) when the first
// character appeared, recreating the TextField element and killing focus —
// the user had to click the field again after every single character.

import 'package:flight_studio/features/flights/flight_repository.dart';
import 'package:flight_studio/l10n/app_localizations.dart';
import 'package:flight_studio/ui/theme/app_theme.dart';
import 'package:flight_studio/ui/welcome/pages/recent_flights_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    // The model chips construct a detached SettingsController when no
    // AppScope is mounted; its prefs backend must exist in tests.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<void> pumpPage(WidgetTester tester) async {
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
        home: Scaffold(body: RecentFlightsPage(repository: FlightRepository())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'prompt box keeps focus across characters (no re-click required)',
    (tester) async {
      await pumpPage(tester);

      final field = find.byType(TextField);
      expect(field, findsOneWidget);

      await tester.tap(field);
      await tester.pump();

      // First character — this used to be fine.
      await tester.enterText(field, 'a');
      await tester.pump();

      // Second character WITHOUT re-clicking: must still land in the field.
      await tester.enterText(field, 'ab');
      await tester.pump();

      final controller = tester.widget<TextField>(field).controller!;
      expect(controller.text, 'ab');

      // Focus never left the field.
      expect(FocusManager.instance.primaryFocus!.hasFocus, isTrue);
    },
  );
}

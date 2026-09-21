// Splash screen tests: golden-ratio card, scan hint while scanning, and the
// 3-second "no navigation data" hold before navigating on (fresh installs).

import 'package:flight_studio/data/settings/settings_controller.dart';
import 'package:flight_studio/data/settings/settings_enums.dart';
import 'package:flight_studio/l10n/app_localizations.dart';
import 'package:flight_studio/ui/splash/splash_shell.dart';
import 'package:flight_studio/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Future<void> _pumpSplash(
  WidgetTester tester, {
  SettingsController? settings,
}) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final controller = settings ?? SettingsController();
  if (!controller.isLoaded) await controller.load();
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
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
      home: SplashShell(
        next: (_) => const Scaffold(body: Text('WELCOME_REACHED')),
        settings: controller,
      ),
    ),
  );
}

void main() {
  testWidgets('splash shows card with hint, then navigates after the '
      'no-data hold (no DB in test env)', (tester) async {
    await _pumpSplash(tester);

    // While scanning: scanning hint is visible (localized zh key not active
    // here — the delegate resolves en by default test locale).
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('navigation data'), findsOneWidget);
    // Progress bar exists.
    expect(
      find.byWidgetPredicate((w) => w is LinearProgressIndicator),
      findsOneWidget,
    );

    // Scan finishes without data → 3 s hold → navigate to next screen.
    // Advance past the hold in steps so pending timers settle.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle();
    expect(find.text('WELCOME_REACHED'), findsOneWidget);
  });

  testWidgets('splash with scan mode NEVER shows only logo + name '
      '(no progress bar) and still navigates after 3 s', (tester) async {
    final settings = SettingsController();
    await settings.load();
    await settings.setSplashScanMode(SplashScanMode.never);

    await _pumpSplash(tester, settings: settings);
    await tester.pump(const Duration(milliseconds: 200));

    // No progress content at all.
    expect(
      find.byWidgetPredicate((w) => w is LinearProgressIndicator),
      findsNothing,
    );
    expect(find.textContaining('navigation data'), findsNothing);

    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle();
    expect(find.text('WELCOME_REACHED'), findsOneWidget);
  });
}

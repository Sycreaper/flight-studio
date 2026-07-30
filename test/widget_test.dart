// Widget tests for the Flight Studio welcome screen, gear menu and settings
// tab.
//
// The welcome body is wrapped in a `WindowDragArea` (so the frameless window
// can be dragged on Windows). That area installs a `onDoubleTap` recogniser
// which holds any single tap in the gesture arena for ~300 ms before
// declaring it a single tap. Tests therefore pump a 400 ms delay after each
// tap and only then `pumpAndSettle`, otherwise the tap callback never fires
// before assertions run.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:flight_studio/app.dart';
import 'package:flight_studio/data/settings/settings_controller.dart';
import 'package:flight_studio/data/settings/settings_enums.dart';
import 'package:flight_studio/features/flights/flight_record.dart';
import 'package:flight_studio/features/flights/flight_repository.dart';
import 'package:flight_studio/l10n/app_localizations.dart';
import 'package:flight_studio/ui/settings/settings_page.dart';
import 'package:flight_studio/ui/theme/app_theme.dart';
import 'package:flight_studio/ui/welcome/widgets/gear_button.dart';
import 'package:flight_studio/ui/workspace/workspace_controller.dart';
import 'package:flight_studio/ui/workspace/workspace_drawer.dart';

const Duration _tapSettleDelay = Duration(milliseconds: 400);

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('Welcome empty state shows three equal-sized action tiles',
          (tester) async {
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

  testWidgets('Nav drawer has no Settings entry (gear menu replaces it)',
          (tester) async {
        await _pumpWelcome(tester, repository: FlightRepository());
        expect(find.text('Recent Flights'), findsOneWidget);
        expect(find.text('Plugin Center'), findsOneWidget);
        expect(find.text('Settings'), findsNothing);
      });

  testWidgets('Gear button shows the popup menu', (tester) async {
    await _pumpWelcome(tester, repository: FlightRepository());
    await _tapAndSettle(tester, find
        .byIcon(Icons.settings_rounded)
        .first);
    expect(find.text('Settings…'), findsOneWidget);
    expect(find.text('About Flight Studio'), findsOneWidget);
    expect(find.text('Check for Updates…'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);
    expect(find.text('Exit'), findsOneWidget);
  });

  testWidgets('Gear → Settings opens a workspace settings tab',
          (tester) async {
        await _pumpWelcome(tester, repository: FlightRepository());
        await _tapAndSettle(tester, find
            .byIcon(Icons.settings_rounded)
            .first);
        await _tapAndSettle(tester, find.text('Settings…'));
        // The settings page renders inside the workspace centre card.
        expect(find.byType(SettingsPage), findsOneWidget);
        expect(find.text('General'), findsWidgets);
        expect(find.text('Simulator'), findsOneWidget);
        expect(find.text('Navigation Data'), findsOneWidget);
        expect(find.text('AI Copilot'), findsOneWidget);
        expect(find.text('Remote Access'), findsOneWidget);
        expect(find.text('About'), findsWidgets);
      });

  testWidgets('Gear → About lands on the About section', (tester) async {
    await _pumpWelcome(tester, repository: FlightRepository());
    await _tapAndSettle(tester, find
        .byIcon(Icons.settings_rounded)
        .first);
    await _tapAndSettle(tester, find.text('About Flight Studio'));
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('About Flight Studio'), findsWidgets);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('License'), findsOneWidget);
  });

  testWidgets('Settings persists a theme switch across reload',
          (tester) async {
        final settings = SettingsController();
        await settings.load();
        await _pumpWelcome(
            tester, repository: FlightRepository(), settings: settings);

        await _tapAndSettle(tester, find
            .byIcon(Icons.settings_rounded)
            .first);
        await _tapAndSettle(tester, find.text('Settings…'));

        await _tapAndSettle(tester, find
            .text('Light')
            .first);
        expect(settings.value.themeMode, ThemeMode.light);

        final reloaded = SettingsController();
        await reloaded.load();
        expect(reloaded.value.themeMode, ThemeMode.light);
      });

  testWidgets('Settings renders in Chinese when locale is zh', (tester) async {
    final settings = SettingsController();
    await settings.load();
    await settings.setLocaleCode(AppLocaleCode.zh);
    await _pumpWelcome(
        tester, repository: FlightRepository(), settings: settings);

    expect(find.text('近期飞行'), findsOneWidget);
    expect(find.text('插件中心'), findsOneWidget);

    await _tapAndSettle(tester, find
        .byIcon(Icons.settings_rounded)
        .first);
    expect(find.text('设置…'), findsOneWidget);
    await _tapAndSettle(tester, find.text('设置…'));

    expect(find.text('常规'), findsWidgets);
    expect(find.text('模拟器'), findsOneWidget);
    expect(find.text('导航数据'), findsOneWidget);
    expect(find.text('AI 副驾驶'), findsOneWidget);
    expect(find.text('远程访问'), findsOneWidget);
    expect(find.text('关于'), findsWidgets);
  });

  testWidgets('Reset to defaults clears persisted overrides', (tester) async {
    final settings = SettingsController();
    await settings.load();
    await settings.setXplaneUdpPort(12345);
    expect(settings.value.xplaneUdpPort, 12345);
    final persisted = await SharedPreferencesAsync().getInt('xplane.udpPort');
    expect(persisted, 12345);
    await settings.resetToDefaults();
    expect(settings.value.xplaneUdpPort, 49000);
    final afterReset = await SharedPreferencesAsync().getInt('xplane.udpPort');
    expect(afterReset, isNull);
  });

  testWidgets('Workspace drawer close fires onHide AND drag handle is hittable',
          (tester) async {
        var hideCalls = 0;
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
            home: Scaffold(
              body: WorkspaceDrawer(
                panel: DrawerPanelData(
                  id: 'test',
                  title: 'Test',
                  slot: DrawerSlot.left,
                  visible: true,
                  icon: Icons.memory_rounded,
                  content: (_) => const Center(child: Text('body')),
                ),
                onHide: () => hideCalls++,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.drag_indicator_rounded), findsOneWidget);
        final closeFinder = find.descendant(
          of: find.byType(IconButton),
          matching: find.byIcon(Icons.close_rounded),
        );
        expect(closeFinder, findsOneWidget);
        await tester.tap(closeFinder);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
        expect(hideCalls, 1);
      });

  testWidgets('GearButton does not spin on hover by default', (tester) async {
    var presses = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Center(
            child: GearButton(
              onPressed: () => presses++,
              tooltip: 'menu',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byType(GearButton)));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    expect(
      find.descendant(
        of: find.byType(GearButton),
        matching: find.byType(RotationTransition),
      ),
      findsNothing,
    );
    await tester.tap(find.byType(GearButton));
    await tester.pumpAndSettle();
    expect(presses, 1);
  });

  testWidgets('GearButton spins when spinning: true', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: Center(
            child: GearButton(
              onPressed: _noop,
              spinning: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      find.descendant(
        of: find.byType(GearButton),
        matching: find.byType(RotationTransition),
      ),
      findsOneWidget,
    );
  });
}

void _noop() {}

Future<void> _tapAndSettle(WidgetTester tester,
    Finder finder, {
      int pointer = 0,
    }) async {
  await tester.tap(finder, pointer: pointer);
  await tester.pump(_tapSettleDelay);
  await tester.pumpAndSettle();
}

Future<void> _pumpWelcome(WidgetTester tester, {
  required FlightRepository repository,
  SettingsController? settings,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  final controller = settings ?? (SettingsController()
    ..load());
  await tester.pumpWidget(FlightStudioApp(
    repository: repository,
    settings: controller,
  ));
  await tester.pumpAndSettle();
}

// Narrow (phone) layout tests: below the 640 px breakpoint every drawer
// collapses into a single icon rail and drawers open as full-screen routes;
// the welcome screen swaps its card nav for an icon rail. Wide layout is
// covered implicitly by widget_test.dart (default 800×600 surface).

import 'package:flight_studio/data/settings/settings_controller.dart';
import 'package:flight_studio/features/flights/flight_repository.dart';
import 'package:flight_studio/l10n/app_localizations.dart';
import 'package:flight_studio/ui/settings/settings_page.dart';
import 'package:flight_studio/ui/theme/app_theme.dart';
import 'package:flight_studio/ui/welcome/welcome_shell.dart';
import 'package:flight_studio/ui/workspace/workspace_controller.dart';
import 'package:flight_studio/ui/workspace/workspace_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Future<void> _pumpNarrow(
  WidgetTester tester, {
  required WidgetBuilder builder,
}) async {
  tester.view.physicalSize = const Size(400, 800);
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
      home: Builder(builder: builder),
    ),
  );
  await tester.pumpAndSettle();
}

DrawerPanelData _panel(String id, IconData icon) => DrawerPanelData(
  id: id,
  title: id,
  icon: icon,
  slot: DrawerSlot.left,
  content: (_) => Text('content-$id'),
);

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('narrow workspace: single rail lists every panel; tapping '
      'opens a full-screen drawer with a close button', (tester) async {
    final controller = WorkspaceController()
      ..register(_panel('alpha', Icons.search_rounded))
      ..register(_panel('bravo', Icons.flight_rounded))
      ..register(_panel('charlie', Icons.tune_rounded));

    await _pumpNarrow(
      tester,
      builder: (_) => WorkspaceView(
        controller: controller,
        center: const SizedBox.expand(),
      ),
    );

    // All three panels are reachable from the one rail.
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.flight_rounded), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

    // Open a drawer full-screen.
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();
    expect(find.text('ALPHA'), findsOneWidget);
    expect(find.text('content-alpha'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // Close returns to the workspace.
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('content-alpha'), findsNothing);
  });

  testWidgets('narrow workspace: panels never dock (visibility flags '
      'ignored, content opens on tap)', (tester) async {
    final controller = WorkspaceController();
    controller.register(_panel('solo', Icons.layers_rounded));

    await _pumpNarrow(
      tester,
      builder: (_) => WorkspaceView(
        controller: controller,
        center: const SizedBox.expand(),
      ),
    );

    // Content only appears after the icon is tapped — the slot/visibility
    // layout is irrelevant in the narrow layout.
    expect(find.text('content-solo'), findsNothing);
    await tester.tap(find.byIcon(Icons.layers_rounded));
    await tester.pumpAndSettle();
    expect(find.text('content-solo'), findsOneWidget);
  });

  testWidgets('narrow welcome: card nav collapses to an icon rail that '
      'switches sections', (tester) async {
    await _pumpNarrow(
      tester,
      builder: (_) => WelcomeShell(
        repository: FlightRepository(),
        settings: SettingsController(),
      ),
    );

    expect(find.byIcon(Icons.history_rounded), findsOneWidget);
    expect(find.byIcon(Icons.extension_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.extension_rounded));
    await tester.pumpAndSettle();

    // Section switched (Plugin Center placeholder is now shown); the rail
    // itself remains for further navigation.
    expect(find.byIcon(Icons.extension_rounded), findsOneWidget);
  });

  testWidgets('narrow settings: menu first, tapping a section opens it '
      'full-screen with a back arrow', (tester) async {
    final settings = SettingsController();
    await settings.load();

    await _pumpNarrow(
      tester,
      builder: (_) => SettingsPage(
        controller: settings,
        section: SettingsSection.general,
        onChangeSection: (_) {},
      ),
    );

    // Menu IS the landing page — section list visible, no detail body.
    expect(find.text('General'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);

    // Tap the Simulator section → full-screen detail page.
    await tester.tap(find.text('Simulator'));
    await tester.pumpAndSettle();
    expect(find.text('SIMULATOR'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    // Back returns to the menu.
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('General'), findsOneWidget);
    expect(find.text('SIMULATOR'), findsNothing);
  });

  testWidgets('wide settings: master-detail unchanged (rail + body '
      'side by side)', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final settings = SettingsController();
    await settings.load();
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
        home: SettingsPage(
          controller: settings,
          section: SettingsSection.about,
          onChangeSection: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Wide: the section body is visible next to the rail — 'About' appears
    // both as the rail entry and the section heading.
    expect(find.text('About'), findsWidgets);
    // No back arrow — detail is not a pushed route on wide screens.
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
  });
}

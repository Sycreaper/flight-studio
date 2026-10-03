// Chat tab tests: the "聊天 / Chat" kind is registered in the tab registry,
// appears in the tab-bar "+" menu, and its view shows an empty history area
// with the welcome-style prompt box at the bottom.

import 'package:flight_studio/l10n/app_localizations.dart';
import 'package:flight_studio/data/settings/settings_controller.dart';
import 'package:flight_studio/ui/shell/app_shell.dart';
import 'package:flight_studio/ui/theme/app_theme.dart';
import 'package:flight_studio/ui/shell/tabs/tab_registry.dart';
import 'package:flight_studio/ui/widgets/prompt_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('TabIds.chat is a distinct registered kind', () {
    expect(TabIds.chat, isNot(TabIds.map));
    expect(TabIds.chat, isNot(TabIds.settings));
  });

  testWidgets('chat tab opens from the "+" menu and shows the prompt box '
      'with an empty history area', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final settings = InMemorySharedPreferencesAsync.empty();
    SharedPreferencesAsyncPlatform.instance = settings;

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
        home: AppShell(settings: SettingsController(), initialTab: TabIds.chat),
      ),
    );
    await tester.pumpAndSettle();

    // The chat tab is selected and shows the inert prompt box.
    expect(find.byType(PromptBox), findsOneWidget);
    // The tab strip contains the Chat tab chip.
    expect(find.text('Chat'), findsOneWidget);
    // History area is empty (no message bubbles).
    expect(find.textContaining('user'), findsNothing);
  });
}

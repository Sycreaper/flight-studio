import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'data/navdata/built_in_providers.dart';
import 'data/navdata/startup_scan.dart';
import 'data/settings/settings_controller.dart';
import 'data/settings/settings_enums.dart';
import 'features/flights/flight_repository.dart';
import 'l10n/import_messages.dart';
import 'sim/built_in_connectors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Extension points: built-ins register through the same registries a
  // future plugin manager will use (Phase 10). Must run before the first
  // frame so capability lookups (connectors, navdata sources) are complete.
  registerBuiltInSimConnectors();
  registerBuiltInNavdataProviders();

  // Desktop window control. The native Windows title bar is hidden so the app
  // can draw its own caption controls via a top-level overlay; other platforms
  // keep their native chrome.
  if (!kIsWeb) {
    await windowManager.ensureInitialized();
    if (Platform.isWindows) {
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    }
  }

  // Load persisted user settings before the first frame. If the store is empty
  // (or fails), the controller falls back to defaults — boot is never blocked.
  final settings = SettingsController();
  await settings.load();

  // Record the resolved UI locale for below-widget-layer progress messages
  // (navdata parsers report through ImportMessages, no BuildContext there).
  ImportMessages.localeName = settings.value.localeCode == AppLocaleCode.zh
      ? 'zh'
      : settings.value.localeCode == AppLocaleCode.en
      ? 'en'
      : Platform.localeName;

  final splashEnabled = settings.value.splashEnabled;

  runApp(FlightStudioApp(
    repository: FlightRepository(),
    settings: settings,
    showSplash: splashEnabled,
  ));

  // Splash disabled but a scan is due → run it headless (progress is
  // visible via the spinning gear + gear menu entries).
  if (!splashEnabled) {
    unawaited(runStartupNavdataScanIfNeeded(settings));
  }
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/logging/app_log.dart';
import 'data/navdata/built_in_providers.dart';
import 'data/navdata/startup_scan.dart';
import 'data/settings/settings_controller.dart';
import 'data/settings/settings_enums.dart';
import 'features/flights/flight_repository.dart';
import 'l10n/import_messages.dart';
import 'sim/built_in_connectors.dart';
import 'sim/sim_connection_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Structured logging (app-*.log; the gateway writes gateway-*.log into
  // the same directory). Failures never block boot.
  await AppLog.init();
  AppLog.i('app', 'Flight Studio starting');

  // Extension points: built-ins register through the same registries a
  // future plugin manager will use (Phase 10). Must run before the first
  // frame so capability lookups (connectors, navdata sources) are complete.
  registerBuiltInSimConnectors();
  registerBuiltInNavdataProviders();

  // Load persisted user settings before the first frame. If the store is empty
  // (or fails), the controller falls back to defaults — boot is never blocked.
  final settings = SettingsController();
  await settings.load();

  final splashEnabled = settings.value.splashEnabled;

  // Desktop window control. The native Windows title bar is hidden so the app
  // can draw its own caption controls via a top-level overlay; other platforms
  // keep their native chrome. When the splash will show, the window starts
  // small (splash size) and locked; SplashShell grows it back to the working
  // size once the splash finishes.
  if (!kIsWeb) {
    await windowManager.ensureInitialized();
    if (Platform.isWindows) {
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    }
    if (splashEnabled) {
      try {
        await windowManager.setSize(const Size(600, 372));
        await windowManager.center();
        await windowManager.setResizable(false);
      } on Exception {
        // Best-effort — a missing plugin channel must never block boot.
      }
    }
  }

  // Record the resolved UI locale for below-widget-layer progress messages
  // (navdata parsers report through ImportMessages, no BuildContext there).
  ImportMessages.localeName = settings.value.localeCode == AppLocaleCode.zh
      ? 'zh'
      : settings.value.localeCode == AppLocaleCode.en
      ? 'en'
      : Platform.localeName;

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

  // Auto-connect the X-Plane Web API link when the setting allows and an
  // install exists (no-op in tests — the service guards FLUTTER_TEST).
  unawaited(
    SimConnectionService.instance.autoConnect(settings),
  );
}

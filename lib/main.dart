import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'data/settings/settings_controller.dart';
import 'features/flights/flight_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(FlightStudioApp(
    repository: FlightRepository(),
    settings: settings,
  ));
}

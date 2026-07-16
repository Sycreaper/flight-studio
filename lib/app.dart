import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/flights/flight_repository.dart';
import 'l10n/app_localizations.dart';
import 'ui/shell/window_chrome.dart';
import 'ui/theme/app_theme.dart';
import 'ui/welcome/welcome_shell.dart';

/// Root widget for Flight Studio. Wires the dark JetBrains-style theme and
/// localization delegates to the welcome/home screen.
///
/// On Windows the native title bar is hidden; a top-level overlay draws the
/// caption controls so every screen (welcome, main, future windows) gets them
/// automatically.
class FlightStudioApp extends StatelessWidget {
  FlightStudioApp({super.key, FlightRepository? repository})
      : _repository = repository ?? FlightRepository();

  final FlightRepository _repository;

  static final bool _captionOverlay =
      !kIsWeb && Platform.isWindows;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flight Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        if (!_captionOverlay) return child ?? const SizedBox();
        // The navigator (`child`) is non-positioned so the Stack sizes to it;
        // the caption controls float on top at the top-right corner.
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            const Positioned(
              top: 0,
              right: 0,
              child: WindowCaptionControls(),
            ),
          ],
        );
      },
      home: WelcomeShell(repository: _repository),
    );
  }
}

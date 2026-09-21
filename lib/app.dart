import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/settings/settings_controller.dart';
import 'features/flights/flight_repository.dart';
import 'l10n/app_localizations.dart';
import 'ui/settings/settings_window.dart';
import 'ui/shell/window_chrome.dart';
import 'ui/splash/splash_shell.dart';
import 'ui/theme/app_theme.dart';
import 'ui/welcome/welcome_shell.dart';

/// Root widget for Flight Studio. Wires theme, localization delegates and the
/// Windows caption overlay, then hosts the welcome/home screen.
///
/// Theme mode (`dark` / `light` / `system`) and interface language (`en` /
/// `zh` / `system`) are read from [settings]; both switch live without an app
/// restart. On Windows the native title bar is hidden; a top-level overlay
/// draws the caption controls so every screen (welcome, main, future windows)
/// gets them automatically.
class FlightStudioApp extends StatelessWidget {
  FlightStudioApp({
    super.key,
    FlightRepository? repository,
    SettingsController? settings,
    this.showSplash = true,
  })
      : _repository = repository ?? FlightRepository(),
        _settings = settings ?? SettingsController();

  final FlightRepository _repository;
  final SettingsController _settings;

  /// When true (default) the app opens on the navdata-scan splash screen and
  /// transitions to the welcome screen when the scan finishes. Tests pass
  /// `false` to land directly on the welcome screen.
  final bool showSplash;

  static final bool _captionOverlay = !kIsWeb && Platform.isWindows;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      settings: _settings,
      child: ListenableBuilder(
        listenable: _settings,
        builder: (context, _) {
          final s = _settings.value;
          // Apply the user-selected interface font to both theme variants —
          // live, no restart needed. `null` keeps the platform default.
          final family = s.fontFamily;
          final light = AppTheme.light();
          final dark = AppTheme.dark();
          final themedLight = (family == null || family.isEmpty)
              ? light
              : light.copyWith(
              textTheme: light.textTheme.apply(fontFamily: family));
          final themedDark = (family == null || family.isEmpty)
              ? dark
              : dark.copyWith(
              textTheme: dark.textTheme.apply(fontFamily: family));
          return MaterialApp(
            title: 'Flight Studio',
            debugShowCheckedModeBanner: false,
            theme: themedLight,
            darkTheme: themedDark,
            themeMode: s.themeMode,
            locale: s.localeCode.toLocale(),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              if (!_captionOverlay) return child ?? const SizedBox();
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
            home: showSplash
                ? SplashShell(
              next: (context) =>
                  WelcomeShell(
                    repository: _repository,
                    settings: _settings,
                  ),
              settings: _settings,
            )
                : WelcomeShell(
              repository: _repository,
              settings: _settings,
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/flights/flight_repository.dart';
import 'l10n/app_localizations.dart';
import 'ui/theme/app_theme.dart';
import 'ui/welcome/welcome_shell.dart';

/// Root widget for Flight Studio. Wires the dark JetBrains-style theme and
/// localization delegates to the welcome/home screen.
class FlightStudioApp extends StatelessWidget {
  FlightStudioApp({super.key, FlightRepository? repository})
      : _repository = repository ?? FlightRepository();

  final FlightRepository _repository;

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
      home: WelcomeShell(repository: _repository),
    );
  }
}

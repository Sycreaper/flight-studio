import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Application display name
  ///
  /// In en, this message translates to:
  /// **'Flight Studio'**
  String get appName;

  /// No description provided for @navRecentFlights.
  ///
  /// In en, this message translates to:
  /// **'Recent Flights'**
  String get navRecentFlights;

  /// No description provided for @navPluginCenter.
  ///
  /// In en, this message translates to:
  /// **'Plugin Center'**
  String get navPluginCenter;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @createFirstFlight.
  ///
  /// In en, this message translates to:
  /// **'Create your first flight'**
  String get createFirstFlight;

  /// No description provided for @createFlight.
  ///
  /// In en, this message translates to:
  /// **'Create Flight'**
  String get createFlight;

  /// No description provided for @worldMap.
  ///
  /// In en, this message translates to:
  /// **'World Map'**
  String get worldMap;

  /// No description provided for @flightAcademy.
  ///
  /// In en, this message translates to:
  /// **'Flight Academy'**
  String get flightAcademy;

  /// No description provided for @createFlightHint.
  ///
  /// In en, this message translates to:
  /// **'Plan a new route from scratch'**
  String get createFlightHint;

  /// No description provided for @worldMapHint.
  ///
  /// In en, this message translates to:
  /// **'Explore the global map and airports'**
  String get worldMapHint;

  /// No description provided for @flightAcademyHint.
  ///
  /// In en, this message translates to:
  /// **'Learn flight planning and procedures'**
  String get flightAcademyHint;

  /// No description provided for @searchFlights.
  ///
  /// In en, this message translates to:
  /// **'Search flights…'**
  String get searchFlights;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No flights match your search'**
  String get noResults;

  /// No description provided for @pluginCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Plugin Center'**
  String get pluginCenterTitle;

  /// No description provided for @pluginCenterDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage simulator bridges and extensions'**
  String get pluginCenterDesc;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Application preferences'**
  String get settingsDesc;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @tabMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get tabMap;

  /// No description provided for @tabFlightPlan.
  ///
  /// In en, this message translates to:
  /// **'Flight Plan'**
  String get tabFlightPlan;

  /// No description provided for @tabMapUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get tabMapUnnamed;

  /// No description provided for @tabPlanUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Flight Plan'**
  String get tabPlanUnnamed;

  /// No description provided for @addTab.
  ///
  /// In en, this message translates to:
  /// **'Add tab'**
  String get addTab;

  /// No description provided for @newMapTab.
  ///
  /// In en, this message translates to:
  /// **'New Map'**
  String get newMapTab;

  /// No description provided for @newFlightPlanTab.
  ///
  /// In en, this message translates to:
  /// **'New Flight Plan'**
  String get newFlightPlanTab;

  /// No description provided for @closeTab.
  ///
  /// In en, this message translates to:
  /// **'Close tab'**
  String get closeTab;

  /// No description provided for @noOpenTabs.
  ///
  /// In en, this message translates to:
  /// **'No open tabs'**
  String get noOpenTabs;

  /// No description provided for @clickPlusToOpen.
  ///
  /// In en, this message translates to:
  /// **'Click the + on the right to open a new tab'**
  String get clickPlusToOpen;

  /// No description provided for @sectionFlightInfo.
  ///
  /// In en, this message translates to:
  /// **'Flight Information'**
  String get sectionFlightInfo;

  /// No description provided for @sectionRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get sectionRoute;

  /// No description provided for @sectionPerformance.
  ///
  /// In en, this message translates to:
  /// **'Fuel & Performance'**
  String get sectionPerformance;

  /// No description provided for @sectionProcedures.
  ///
  /// In en, this message translates to:
  /// **'Procedures'**
  String get sectionProcedures;

  /// No description provided for @fieldAircraft.
  ///
  /// In en, this message translates to:
  /// **'Aircraft'**
  String get fieldAircraft;

  /// No description provided for @fieldAirframe.
  ///
  /// In en, this message translates to:
  /// **'Airframe / Registration'**
  String get fieldAirframe;

  /// No description provided for @fieldAirline.
  ///
  /// In en, this message translates to:
  /// **'Airline'**
  String get fieldAirline;

  /// No description provided for @fieldFlightNumber.
  ///
  /// In en, this message translates to:
  /// **'Flight Number'**
  String get fieldFlightNumber;

  /// No description provided for @fieldCallsign.
  ///
  /// In en, this message translates to:
  /// **'Callsign'**
  String get fieldCallsign;

  /// No description provided for @fieldDeparture.
  ///
  /// In en, this message translates to:
  /// **'Departure (ICAO)'**
  String get fieldDeparture;

  /// No description provided for @fieldDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination (ICAO)'**
  String get fieldDestination;

  /// No description provided for @fieldAlternate.
  ///
  /// In en, this message translates to:
  /// **'Alternate (ICAO)'**
  String get fieldAlternate;

  /// No description provided for @fieldCruiseLevel.
  ///
  /// In en, this message translates to:
  /// **'Cruise Level (FL)'**
  String get fieldCruiseLevel;

  /// No description provided for @fieldCostIndex.
  ///
  /// In en, this message translates to:
  /// **'Cost Index'**
  String get fieldCostIndex;

  /// No description provided for @fieldRoute.
  ///
  /// In en, this message translates to:
  /// **'Route string'**
  String get fieldRoute;

  /// No description provided for @fieldContingency.
  ///
  /// In en, this message translates to:
  /// **'Contingency fuel'**
  String get fieldContingency;

  /// No description provided for @fieldReserve.
  ///
  /// In en, this message translates to:
  /// **'Reserve fuel'**
  String get fieldReserve;

  /// No description provided for @fieldTaxiFuel.
  ///
  /// In en, this message translates to:
  /// **'Taxi fuel'**
  String get fieldTaxiFuel;

  /// No description provided for @fieldExtraFuel.
  ///
  /// In en, this message translates to:
  /// **'Extra fuel'**
  String get fieldExtraFuel;

  /// No description provided for @fieldUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get fieldUnits;

  /// No description provided for @fieldSid.
  ///
  /// In en, this message translates to:
  /// **'SID'**
  String get fieldSid;

  /// No description provided for @fieldStar.
  ///
  /// In en, this message translates to:
  /// **'STAR'**
  String get fieldStar;

  /// No description provided for @fieldApproach.
  ///
  /// In en, this message translates to:
  /// **'Approach'**
  String get fieldApproach;

  /// No description provided for @fieldPlanDetail.
  ///
  /// In en, this message translates to:
  /// **'Plan detail'**
  String get fieldPlanDetail;

  /// No description provided for @unitsKg.
  ///
  /// In en, this message translates to:
  /// **'Kilograms'**
  String get unitsKg;

  /// No description provided for @unitsLb.
  ///
  /// In en, this message translates to:
  /// **'Pounds'**
  String get unitsLb;

  /// No description provided for @detailFull.
  ///
  /// In en, this message translates to:
  /// **'Detailed'**
  String get detailFull;

  /// No description provided for @detailRouteOnly.
  ///
  /// In en, this message translates to:
  /// **'Route Only'**
  String get detailRouteOnly;

  /// No description provided for @calculatePlan.
  ///
  /// In en, this message translates to:
  /// **'Calculate Plan'**
  String get calculatePlan;

  /// No description provided for @resetForm.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetForm;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

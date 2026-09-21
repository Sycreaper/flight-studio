import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

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

  /// No description provided for @settingsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search settings…'**
  String get settingsSearchHint;

  /// No description provided for @settingsResetDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get settingsResetDefaults;

  /// No description provided for @settingsResetDefaultsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset all settings to their defaults? This cannot be undone.'**
  String get settingsResetDefaultsConfirm;

  /// No description provided for @settingsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settingsReset;

  /// No description provided for @settingsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancel;

  /// No description provided for @settingsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get settingsClose;

  /// No description provided for @settingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsSave;

  /// No description provided for @settingsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get settingsEdit;

  /// No description provided for @settingsBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse…'**
  String get settingsBrowse;

  /// No description provided for @settingsNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settingsNotSet;

  /// No description provided for @settingsRestartHint.
  ///
  /// In en, this message translates to:
  /// **'Restart Flight Studio for this change to take full effect.'**
  String get settingsRestartHint;

  /// No description provided for @settingsPlannedBadge.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get settingsPlannedBadge;

  /// No description provided for @settingsConnectedBadge.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get settingsConnectedBadge;

  /// No description provided for @settingsDisconnectedBadge.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get settingsDisconnectedBadge;

  /// No description provided for @gearMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get gearMenuTooltip;

  /// No description provided for @gearMenuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings…'**
  String get gearMenuSettings;

  /// No description provided for @gearMenuAbout.
  ///
  /// In en, this message translates to:
  /// **'About Flight Studio'**
  String get gearMenuAbout;

  /// No description provided for @gearMenuCheckUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates…'**
  String get gearMenuCheckUpdates;

  /// No description provided for @gearMenuCheckUpdatesNone.
  ///
  /// In en, this message translates to:
  /// **'You are running the latest version.'**
  String get gearMenuCheckUpdatesNone;

  /// No description provided for @gearMenuHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get gearMenuHelp;

  /// No description provided for @gearMenuExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get gearMenuExit;

  /// No description provided for @toolbarHome.
  ///
  /// In en, this message translates to:
  /// **'Back to welcome'**
  String get toolbarHome;

  /// No description provided for @aboutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'About Flight Studio'**
  String get aboutDialogTitle;

  /// No description provided for @settingsCategoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsCategoryGeneral;

  /// No description provided for @settingsCategoryGeneralDesc.
  ///
  /// In en, this message translates to:
  /// **'Appearance, language and startup behaviour.'**
  String get settingsCategoryGeneralDesc;

  /// No description provided for @settingsCategorySimulator.
  ///
  /// In en, this message translates to:
  /// **'Simulator'**
  String get settingsCategorySimulator;

  /// No description provided for @settingsCategorySimulatorDesc.
  ///
  /// In en, this message translates to:
  /// **'X-Plane, MSFS and Prepar3D bridges.'**
  String get settingsCategorySimulatorDesc;

  /// No description provided for @settingsCategoryNavdata.
  ///
  /// In en, this message translates to:
  /// **'Navigation Data'**
  String get settingsCategoryNavdata;

  /// No description provided for @settingsCategoryNavdataDesc.
  ///
  /// In en, this message translates to:
  /// **'Airports, airways, procedures and AIRAC sources.'**
  String get settingsCategoryNavdataDesc;

  /// No description provided for @settingsCategoryAi.
  ///
  /// In en, this message translates to:
  /// **'AI Copilot'**
  String get settingsCategoryAi;

  /// No description provided for @settingsCategoryAiDesc.
  ///
  /// In en, this message translates to:
  /// **'Bring your own LLM key and configure tool access.'**
  String get settingsCategoryAiDesc;

  /// No description provided for @settingsCategoryRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote Access'**
  String get settingsCategoryRemote;

  /// No description provided for @settingsCategoryRemoteDesc.
  ///
  /// In en, this message translates to:
  /// **'Embedded server for phone and web clients.'**
  String get settingsCategoryRemoteDesc;

  /// No description provided for @settingsCategoryAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsCategoryAbout;

  /// No description provided for @settingsCategoryAboutDesc.
  ///
  /// In en, this message translates to:
  /// **'Version, license and credits.'**
  String get settingsCategoryAboutDesc;

  /// No description provided for @settingsAppearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceTitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get languageSystem;

  /// No description provided for @settingsFontFamily.
  ///
  /// In en, this message translates to:
  /// **'Interface font'**
  String get settingsFontFamily;

  /// No description provided for @settingsFontFamilyHint.
  ///
  /// In en, this message translates to:
  /// **'Applies to the whole application. Takes effect immediately.'**
  String get settingsFontFamilyHint;

  /// No description provided for @settingsFontDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get settingsFontDefault;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeHint.
  ///
  /// In en, this message translates to:
  /// **'Dark is recommended for cockpit use at night.'**
  String get settingsThemeHint;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'Application interface language.'**
  String get settingsLanguageHint;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// No description provided for @settingsLanguageZh.
  ///
  /// In en, this message translates to:
  /// **'中文（简体）'**
  String get settingsLanguageZh;

  /// No description provided for @settingsStartupTitle.
  ///
  /// In en, this message translates to:
  /// **'Startup'**
  String get settingsStartupTitle;

  /// No description provided for @settingsReopenLastWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Reopen last workspace on launch'**
  String get settingsReopenLastWorkspace;

  /// No description provided for @settingsReopenLastWorkspaceHint.
  ///
  /// In en, this message translates to:
  /// **'Skip the welcome screen and jump straight into your last session.'**
  String get settingsReopenLastWorkspaceHint;

  /// No description provided for @settingsCheckUpdatesOnLaunch.
  ///
  /// In en, this message translates to:
  /// **'Check for updates on launch'**
  String get settingsCheckUpdatesOnLaunch;

  /// No description provided for @settingsCheckUpdatesOnLaunchHint.
  ///
  /// In en, this message translates to:
  /// **'Notify when a new Flight Studio build is available.'**
  String get settingsCheckUpdatesOnLaunchHint;

  /// No description provided for @settingsUnitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Default units'**
  String get settingsUnitsTitle;

  /// No description provided for @settingsUnitsMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric (kg, km)'**
  String get settingsUnitsMetric;

  /// No description provided for @settingsUnitsImperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial (lb, nm)'**
  String get settingsUnitsImperial;

  /// No description provided for @settingsUnitsHint.
  ///
  /// In en, this message translates to:
  /// **'Used by new flight plans and the fuel planner.'**
  String get settingsUnitsHint;

  /// No description provided for @settingsSimulatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Simulator connections'**
  String get settingsSimulatorTitle;

  /// No description provided for @settingsSimulatorDesc.
  ///
  /// In en, this message translates to:
  /// **'Flight Studio reads telemetry and sends commands through per-simulator bridges. Only one simulator needs to be connected at a time.'**
  String get settingsSimulatorDesc;

  /// No description provided for @settingsXplaneTitle.
  ///
  /// In en, this message translates to:
  /// **'X-Plane 12'**
  String get settingsXplaneTitle;

  /// No description provided for @settingsXplaneStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Bridge detected on port {port}'**
  String settingsXplaneStatusConnected(int port);

  /// No description provided for @settingsXplaneStatusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get settingsXplaneStatusDisconnected;

  /// No description provided for @settingsXplaneInstallPath.
  ///
  /// In en, this message translates to:
  /// **'X-Plane install folder'**
  String get settingsXplaneInstallPath;

  /// No description provided for @settingsXplaneInstallHint.
  ///
  /// In en, this message translates to:
  /// **'Location of the X-Plane 12 root (contains ‘Resources’ and ‘Aircraft’).'**
  String get settingsXplaneInstallHint;

  /// No description provided for @settingsXplaneInstallPick.
  ///
  /// In en, this message translates to:
  /// **'Choose folder…'**
  String get settingsXplaneInstallPick;

  /// No description provided for @settingsXplaneInstallClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsXplaneInstallClear;

  /// No description provided for @settingsXplaneUdpPort.
  ///
  /// In en, this message translates to:
  /// **'Telemetry UDP port'**
  String get settingsXplaneUdpPort;

  /// No description provided for @settingsXplaneUdpPortHint.
  ///
  /// In en, this message translates to:
  /// **'Port X-Plane sends Data Output to (default 49000).'**
  String get settingsXplaneUdpPortHint;

  /// No description provided for @settingsXplaneBridgePort.
  ///
  /// In en, this message translates to:
  /// **'Bridge command port'**
  String get settingsXplaneBridgePort;

  /// No description provided for @settingsXplaneBridgePortHint.
  ///
  /// In en, this message translates to:
  /// **'Port the bundled FlyWithLua script listens on (default 49001).'**
  String get settingsXplaneBridgePortHint;

  /// No description provided for @settingsXplaneInstallBridge.
  ///
  /// In en, this message translates to:
  /// **'Install FlyWithLua bridge…'**
  String get settingsXplaneInstallBridge;

  /// No description provided for @settingsXplaneInstallBridgeHint.
  ///
  /// In en, this message translates to:
  /// **'Copies FlightStudioBridge.lua into the FlyWithLua Scripts folder.'**
  String get settingsXplaneInstallBridgeHint;

  /// No description provided for @settingsXplaneTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get settingsXplaneTestConnection;

  /// No description provided for @settingsMsfsTitle.
  ///
  /// In en, this message translates to:
  /// **'MSFS 2020 / 2024 & Prepar3D'**
  String get settingsMsfsTitle;

  /// No description provided for @settingsMsfsPlanned.
  ///
  /// In en, this message translates to:
  /// **'The C++ SimConnect bridge daemon is planned for a later phase. Telemetry and command support for MSFS and Prepar3D will share this adapter.'**
  String get settingsMsfsPlanned;

  /// No description provided for @settingsMsfsBridgePath.
  ///
  /// In en, this message translates to:
  /// **'SimConnect bridge daemon'**
  String get settingsMsfsBridgePath;

  /// No description provided for @settingsMsfsBridgePathHint.
  ///
  /// In en, this message translates to:
  /// **'Auto-discovered when the daemon ships.'**
  String get settingsMsfsBridgePathHint;

  /// No description provided for @settingsNavdataTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigation data sources'**
  String get settingsNavdataTitle;

  /// No description provided for @settingsNavdataDesc.
  ///
  /// In en, this message translates to:
  /// **'Mix and match sources. The trust layer shows where each plan’s data came from and validates AIRAC consistency on import/export.'**
  String get settingsNavdataDesc;

  /// No description provided for @settingsNavdataBundledTitle.
  ///
  /// In en, this message translates to:
  /// **'Bundled (free & open)'**
  String get settingsNavdataBundledTitle;

  /// No description provided for @settingsNavdataOurAirports.
  ///
  /// In en, this message translates to:
  /// **'OurAirports'**
  String get settingsNavdataOurAirports;

  /// No description provided for @settingsNavdataOurAirportsHint.
  ///
  /// In en, this message translates to:
  /// **'Airports, runways, frequencies and navaids (Public Domain).'**
  String get settingsNavdataOurAirportsHint;

  /// No description provided for @settingsNavdataFaaCifp.
  ///
  /// In en, this message translates to:
  /// **'FAA CIFP / NASR'**
  String get settingsNavdataFaaCifp;

  /// No description provided for @settingsNavdataFaaCifpHint.
  ///
  /// In en, this message translates to:
  /// **'U.S. instrument procedures (Public Domain).'**
  String get settingsNavdataFaaCifpHint;

  /// No description provided for @settingsNavdataXplaneNative.
  ///
  /// In en, this message translates to:
  /// **'Parse X-Plane native files'**
  String get settingsNavdataXplaneNative;

  /// No description provided for @settingsNavdataXplaneNativeHint.
  ///
  /// In en, this message translates to:
  /// **'Reads apt.dat, earth_nav.dat, earth_fix.dat and awy.dat directly from the install folder.'**
  String get settingsNavdataXplaneNativeHint;

  /// No description provided for @settingsNavdataRefreshBundled.
  ///
  /// In en, this message translates to:
  /// **'Refresh bundled data'**
  String get settingsNavdataRefreshBundled;

  /// No description provided for @settingsNavdataNavigraphTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigraph (user subscription)'**
  String get settingsNavdataNavigraphTitle;

  /// No description provided for @settingsNavdataNavigraphHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your own Navigraph account. Charts and AIRAC are never bundled or redistributed by Flight Studio.'**
  String get settingsNavdataNavigraphHint;

  /// No description provided for @settingsNavdataNavigraphSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {user}'**
  String settingsNavdataNavigraphSignedIn(String user);

  /// No description provided for @settingsNavdataNavigraphSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get settingsNavdataNavigraphSignedOut;

  /// No description provided for @settingsNavdataNavigraphSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Navigraph…'**
  String get settingsNavdataNavigraphSignIn;

  /// No description provided for @settingsNavdataNavigraphSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsNavdataNavigraphSignOut;

  /// No description provided for @settingsNavdataNavigraphAirac.
  ///
  /// In en, this message translates to:
  /// **'Active AIRAC cycle'**
  String get settingsNavdataNavigraphAirac;

  /// No description provided for @settingsNavdataNavigraphAiracNone.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get settingsNavdataNavigraphAiracNone;

  /// No description provided for @settingsNavdataSimBriefTitle.
  ///
  /// In en, this message translates to:
  /// **'SimBrief (free account)'**
  String get settingsNavdataSimBriefTitle;

  /// No description provided for @settingsNavdataSimBriefHint.
  ///
  /// In en, this message translates to:
  /// **'Link your SimBrief account to import OFPs and route strings. Nothing is redistributed.'**
  String get settingsNavdataSimBriefHint;

  /// No description provided for @settingsNavdataSimBriefLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked to {username}'**
  String settingsNavdataSimBriefLinked(String username);

  /// No description provided for @settingsNavdataSimBriefNotLinked.
  ///
  /// In en, this message translates to:
  /// **'Not linked'**
  String get settingsNavdataSimBriefNotLinked;

  /// No description provided for @settingsNavdataSimBriefLink.
  ///
  /// In en, this message translates to:
  /// **'Link SimBrief account…'**
  String get settingsNavdataSimBriefLink;

  /// No description provided for @settingsNavdataSimBriefUnlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get settingsNavdataSimBriefUnlink;

  /// No description provided for @settingsAiTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Copilot'**
  String get settingsAiTitle;

  /// No description provided for @settingsAiDesc.
  ///
  /// In en, this message translates to:
  /// **'The assistant is constrained to call MCP tools for anything with side effects — it never computes routes or writes files itself. Route calculation, export and simulator commands run as deterministic Dart.'**
  String get settingsAiDesc;

  /// No description provided for @settingsAiProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get settingsAiProvider;

  /// No description provided for @settingsAiProviderOpenAi.
  ///
  /// In en, this message translates to:
  /// **'OpenAI-compatible'**
  String get settingsAiProviderOpenAi;

  /// No description provided for @settingsAiProviderAnthropic.
  ///
  /// In en, this message translates to:
  /// **'Anthropic'**
  String get settingsAiProviderAnthropic;

  /// No description provided for @settingsAiProviderOllama.
  ///
  /// In en, this message translates to:
  /// **'Local (Ollama)'**
  String get settingsAiProviderOllama;

  /// No description provided for @settingsAiProviderHint.
  ///
  /// In en, this message translates to:
  /// **'OpenAI-compatible covers OpenAI, Groq, Together, OpenRouter, LM Studio, etc.'**
  String get settingsAiProviderHint;

  /// No description provided for @settingsAiApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get settingsAiApiKey;

  /// No description provided for @settingsAiApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Stored locally on this device and only ever sent to the provider you pick.'**
  String get settingsAiApiKeyHint;

  /// No description provided for @settingsAiApiKeyHidden.
  ///
  /// In en, this message translates to:
  /// **'Key set (hidden)'**
  String get settingsAiApiKeyHidden;

  /// No description provided for @settingsAiClearApiKey.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsAiClearApiKey;

  /// No description provided for @settingsAiEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Endpoint URL'**
  String get settingsAiEndpoint;

  /// No description provided for @settingsAiEndpointHint.
  ///
  /// In en, this message translates to:
  /// **'Override the provider’s default base URL (e.g. http://localhost:11434 for Ollama).'**
  String get settingsAiEndpointHint;

  /// No description provided for @settingsAiEndpointPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'https://api.openai.com/v1'**
  String get settingsAiEndpointPlaceholder;

  /// No description provided for @settingsAiModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get settingsAiModel;

  /// No description provided for @settingsAiModelHint.
  ///
  /// In en, this message translates to:
  /// **'Example: gpt-4o-mini, claude-3-5-sonnet, llama3.1.'**
  String get settingsAiModelHint;

  /// No description provided for @settingsAiModelPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'model-id'**
  String get settingsAiModelPlaceholder;

  /// No description provided for @settingsAiToolPolicy.
  ///
  /// In en, this message translates to:
  /// **'Tool policy'**
  String get settingsAiToolPolicy;

  /// No description provided for @settingsAiConfirmWrites.
  ///
  /// In en, this message translates to:
  /// **'Require confirmation for write actions'**
  String get settingsAiConfirmWrites;

  /// No description provided for @settingsAiConfirmWritesHint.
  ///
  /// In en, this message translates to:
  /// **'Export, simulator commands and file writes need your approval before they run.'**
  String get settingsAiConfirmWritesHint;

  /// No description provided for @settingsAiAutoRead.
  ///
  /// In en, this message translates to:
  /// **'Allow read tools without confirmation'**
  String get settingsAiAutoRead;

  /// No description provided for @settingsAiAutoReadHint.
  ///
  /// In en, this message translates to:
  /// **'Navdata, weather, telemetry and flight records are surfaced to the model without prompting.'**
  String get settingsAiAutoReadHint;

  /// No description provided for @settingsRemoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Remote access'**
  String get settingsRemoteTitle;

  /// No description provided for @settingsRemoteDesc.
  ///
  /// In en, this message translates to:
  /// **'Host an embedded HTTP/WebSocket server in-process so the companion phone and web clients can watch the moving map, pause the sim and operate the MCDU over LAN.'**
  String get settingsRemoteDesc;

  /// No description provided for @settingsRemoteEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable embedded server'**
  String get settingsRemoteEnable;

  /// No description provided for @settingsRemotePort.
  ///
  /// In en, this message translates to:
  /// **'Listen port'**
  String get settingsRemotePort;

  /// No description provided for @settingsRemotePortHint.
  ///
  /// In en, this message translates to:
  /// **'TCP port the desktop app listens on (default 48080).'**
  String get settingsRemotePortHint;

  /// No description provided for @settingsRemoteToken.
  ///
  /// In en, this message translates to:
  /// **'Access token'**
  String get settingsRemoteToken;

  /// No description provided for @settingsRemoteTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Shared secret every phone/web client must present.'**
  String get settingsRemoteTokenHint;

  /// No description provided for @settingsRemoteRegenerateToken.
  ///
  /// In en, this message translates to:
  /// **'Regenerate token'**
  String get settingsRemoteRegenerateToken;

  /// No description provided for @settingsRemoteStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Server status'**
  String get settingsRemoteStatusTitle;

  /// No description provided for @settingsRemoteNotRunning.
  ///
  /// In en, this message translates to:
  /// **'Not running'**
  String get settingsRemoteNotRunning;

  /// No description provided for @settingsRemoteRunningOn.
  ///
  /// In en, this message translates to:
  /// **'Listening on http://{host}:{port}'**
  String settingsRemoteRunningOn(String host, int port);

  /// No description provided for @settingsRemoteMdns.
  ///
  /// In en, this message translates to:
  /// **'Advertise on local network (mDNS)'**
  String get settingsRemoteMdns;

  /// No description provided for @settingsRemoteMdnsHint.
  ///
  /// In en, this message translates to:
  /// **'Lets the companion apps discover this machine automatically.'**
  String get settingsRemoteMdnsHint;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Flight Studio'**
  String get settingsAboutTitle;

  /// No description provided for @settingsAboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsAboutVersion;

  /// No description provided for @settingsAboutLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get settingsAboutLicense;

  /// No description provided for @settingsAboutLicenseValue.
  ///
  /// In en, this message translates to:
  /// **'MIT — permissive, clean-room reimplementation'**
  String get settingsAboutLicenseValue;

  /// No description provided for @settingsAboutViewLicense.
  ///
  /// In en, this message translates to:
  /// **'View full license'**
  String get settingsAboutViewLicense;

  /// No description provided for @settingsAboutThirdParty.
  ///
  /// In en, this message translates to:
  /// **'Third-party data'**
  String get settingsAboutThirdParty;

  /// No description provided for @settingsAboutThirdPartyDesc.
  ///
  /// In en, this message translates to:
  /// **'Navigraph and SimBrief data is user-licensed and never redistributed. OpenStreetMap tiles are © OSM contributors (ODbL). OurAirports and FAA CIFP/NASR are Public Domain.'**
  String get settingsAboutThirdPartyDesc;

  /// No description provided for @settingsAboutViewThirdParty.
  ///
  /// In en, this message translates to:
  /// **'View third-party notices'**
  String get settingsAboutViewThirdParty;

  /// No description provided for @settingsAboutHomepage.
  ///
  /// In en, this message translates to:
  /// **'Homepage'**
  String get settingsAboutHomepage;

  /// No description provided for @settingsAboutOpenSource.
  ///
  /// In en, this message translates to:
  /// **'Open source on GitHub'**
  String get settingsAboutOpenSource;

  /// No description provided for @settingsAboutInspiredBy.
  ///
  /// In en, this message translates to:
  /// **'Inspired by Little Navmap (no GPL source reused).'**
  String get settingsAboutInspiredBy;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Flight Planner'**
  String get welcomeSubtitle;

  /// No description provided for @ttNewFlightPlan.
  ///
  /// In en, this message translates to:
  /// **'New flight plan'**
  String get ttNewFlightPlan;

  /// No description provided for @ttOpenFlightPlan.
  ///
  /// In en, this message translates to:
  /// **'Open flight plan'**
  String get ttOpenFlightPlan;

  /// No description provided for @ttExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get ttExport;

  /// No description provided for @ttCalculateRoute.
  ///
  /// In en, this message translates to:
  /// **'Calculate route'**
  String get ttCalculateRoute;

  /// No description provided for @ttConnectSim.
  ///
  /// In en, this message translates to:
  /// **'Connect simulator'**
  String get ttConnectSim;

  /// No description provided for @ttPauseSim.
  ///
  /// In en, this message translates to:
  /// **'Pause simulator'**
  String get ttPauseSim;

  /// No description provided for @ttToggleProjection.
  ///
  /// In en, this message translates to:
  /// **'Toggle projection'**
  String get ttToggleProjection;

  /// No description provided for @ttCalculatePlan.
  ///
  /// In en, this message translates to:
  /// **'Calculate plan'**
  String get ttCalculatePlan;

  /// No description provided for @ttResetForm.
  ///
  /// In en, this message translates to:
  /// **'Reset form'**
  String get ttResetForm;

  /// No description provided for @ttImportRoute.
  ///
  /// In en, this message translates to:
  /// **'Import route'**
  String get ttImportRoute;

  /// No description provided for @ttExportPlan.
  ///
  /// In en, this message translates to:
  /// **'Export plan'**
  String get ttExportPlan;

  /// No description provided for @ttFetchSimBrief.
  ///
  /// In en, this message translates to:
  /// **'Fetch from SimBrief'**
  String get ttFetchSimBrief;

  /// No description provided for @ttSavePlan.
  ///
  /// In en, this message translates to:
  /// **'Save plan'**
  String get ttSavePlan;

  /// No description provided for @mapPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapPlaceholder;

  /// No description provided for @mapApiKeyCta.
  ///
  /// In en, this message translates to:
  /// **'Bind your map API key to enable live tiles'**
  String get mapApiKeyCta;

  /// No description provided for @mapLoadError.
  ///
  /// In en, this message translates to:
  /// **'Map failed to load'**
  String get mapLoadError;

  /// No description provided for @mapErrorNoNetwork.
  ///
  /// In en, this message translates to:
  /// **'No network connection — check your internet and retry.'**
  String get mapErrorNoNetwork;

  /// No description provided for @mapError404.
  ///
  /// In en, this message translates to:
  /// **'Tile server returned 404. The tile URL may be incorrect or the server is down.'**
  String get mapError404;

  /// No description provided for @mapErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error {code}'**
  String mapErrorGeneric(String code);

  /// No description provided for @mapRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get mapRetry;

  /// No description provided for @mapZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get mapZoomIn;

  /// No description provided for @mapZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get mapZoomOut;

  /// No description provided for @statusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get statusConnected;

  /// No description provided for @statusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get statusDisconnected;

  /// No description provided for @statusNoNavdata.
  ///
  /// In en, this message translates to:
  /// **'No navdata loaded'**
  String get statusNoNavdata;

  /// No description provided for @statusCpu.
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get statusCpu;

  /// No description provided for @statusGpu.
  ///
  /// In en, this message translates to:
  /// **'GPU'**
  String get statusGpu;

  /// No description provided for @statusMem.
  ///
  /// In en, this message translates to:
  /// **'MEM'**
  String get statusMem;

  /// No description provided for @panelFlightPlans.
  ///
  /// In en, this message translates to:
  /// **'Flight Plans'**
  String get panelFlightPlans;

  /// No description provided for @panelInspector.
  ///
  /// In en, this message translates to:
  /// **'Inspector'**
  String get panelInspector;

  /// No description provided for @panelProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get panelProfile;

  /// No description provided for @hidePanel.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hidePanel;

  /// No description provided for @inspectorHint.
  ///
  /// In en, this message translates to:
  /// **'Double-click a map icon or a search result to see its details here.'**
  String get inspectorHint;

  /// No description provided for @inspectorType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get inspectorType;

  /// No description provided for @inspectorCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get inspectorCoordinates;

  /// No description provided for @inspectorElevation.
  ///
  /// In en, this message translates to:
  /// **'Elevation'**
  String get inspectorElevation;

  /// No description provided for @inspectorFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get inspectorFrequency;

  /// No description provided for @inspectorRunways.
  ///
  /// In en, this message translates to:
  /// **'Runways'**
  String get inspectorRunways;

  /// No description provided for @inspectorIata.
  ///
  /// In en, this message translates to:
  /// **'IATA'**
  String get inspectorIata;

  /// No description provided for @inspectorCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get inspectorCity;

  /// No description provided for @inspectorFlyTo.
  ///
  /// In en, this message translates to:
  /// **'Fly to this point'**
  String get inspectorFlyTo;

  /// No description provided for @inspectorClear.
  ///
  /// In en, this message translates to:
  /// **'Clear inspector'**
  String get inspectorClear;

  /// No description provided for @inspectorFrequencies.
  ///
  /// In en, this message translates to:
  /// **'ATC Frequencies'**
  String get inspectorFrequencies;

  /// No description provided for @inspectorWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get inspectorWeather;

  /// No description provided for @inspectorWeatherUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No weather available for this station.'**
  String get inspectorWeatherUnavailable;

  /// No description provided for @inspectorTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get inspectorTabOverview;

  /// No description provided for @inspectorTabComms.
  ///
  /// In en, this message translates to:
  /// **'Comms'**
  String get inspectorTabComms;

  /// No description provided for @inspectorIcao.
  ///
  /// In en, this message translates to:
  /// **'ICAO'**
  String get inspectorIcao;

  /// No description provided for @inspectorXplaneIdent.
  ///
  /// In en, this message translates to:
  /// **'X-Plane ident'**
  String get inspectorXplaneIdent;

  /// No description provided for @inspectorRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get inspectorRegion;

  /// No description provided for @inspectorCountry.
  ///
  /// In en, this message translates to:
  /// **'Country/region code'**
  String get inspectorCountry;

  /// No description provided for @inspectorMagvar.
  ///
  /// In en, this message translates to:
  /// **'Magnetic declination'**
  String get inspectorMagvar;

  /// No description provided for @inspectorSunTimes.
  ///
  /// In en, this message translates to:
  /// **'Sunrise & sunset'**
  String get inspectorSunTimes;

  /// No description provided for @inspectorNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get inspectorNotAvailable;

  /// No description provided for @inspectorRawReport.
  ///
  /// In en, this message translates to:
  /// **'Raw report'**
  String get inspectorRawReport;

  /// No description provided for @inspectorWindCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get inspectorWindCalm;

  /// No description provided for @splashScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning navigation data…'**
  String get splashScanning;

  /// No description provided for @splashNoNavdata.
  ///
  /// In en, this message translates to:
  /// **'No navigation data found'**
  String get splashNoNavdata;

  /// No description provided for @settingsSplash.
  ///
  /// In en, this message translates to:
  /// **'Splash screen'**
  String get settingsSplash;

  /// No description provided for @settingsSplashHint.
  ///
  /// In en, this message translates to:
  /// **'Show the startup screen while navigation data is scanned'**
  String get settingsSplashHint;

  /// No description provided for @settingsSplashScan.
  ///
  /// In en, this message translates to:
  /// **'Auto-scan navigation data on startup'**
  String get settingsSplashScan;

  /// No description provided for @settingsSplashScanHint.
  ///
  /// In en, this message translates to:
  /// **'How often the full navdata import runs at launch'**
  String get settingsSplashScanHint;

  /// No description provided for @splashScanAlways.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get splashScanAlways;

  /// No description provided for @splashScanAfter14.
  ///
  /// In en, this message translates to:
  /// **'Last scan over 14 days ago'**
  String get splashScanAfter14;

  /// No description provided for @splashScanAfter28.
  ///
  /// In en, this message translates to:
  /// **'Last scan over 28 days ago'**
  String get splashScanAfter28;

  /// No description provided for @splashScanNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get splashScanNever;

  /// No description provided for @navActiveSource.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get navActiveSource;

  /// No description provided for @inspectorDataSource.
  ///
  /// In en, this message translates to:
  /// **'Data source'**
  String get inspectorDataSource;

  /// No description provided for @inspectorRunwayCount.
  ///
  /// In en, this message translates to:
  /// **'Runways'**
  String get inspectorRunwayCount;

  /// No description provided for @inspectorLongestRunway.
  ///
  /// In en, this message translates to:
  /// **'Longest runway'**
  String get inspectorLongestRunway;

  /// No description provided for @airportTypeAirport.
  ///
  /// In en, this message translates to:
  /// **'Airport'**
  String get airportTypeAirport;

  /// No description provided for @airportTypeHeliport.
  ///
  /// In en, this message translates to:
  /// **'Heliport'**
  String get airportTypeHeliport;

  /// No description provided for @airportTypeSeaplane.
  ///
  /// In en, this message translates to:
  /// **'Seaplane'**
  String get airportTypeSeaplane;

  /// No description provided for @navFreqAtis.
  ///
  /// In en, this message translates to:
  /// **'ATIS'**
  String get navFreqAtis;

  /// No description provided for @navFreqCtaf.
  ///
  /// In en, this message translates to:
  /// **'CTAF'**
  String get navFreqCtaf;

  /// No description provided for @navFreqGnd.
  ///
  /// In en, this message translates to:
  /// **'GND'**
  String get navFreqGnd;

  /// No description provided for @navFreqTwr.
  ///
  /// In en, this message translates to:
  /// **'TWR'**
  String get navFreqTwr;

  /// No description provided for @navFreqCld.
  ///
  /// In en, this message translates to:
  /// **'CLD'**
  String get navFreqCld;

  /// No description provided for @navFreqApp.
  ///
  /// In en, this message translates to:
  /// **'APP'**
  String get navFreqApp;

  /// No description provided for @navFreqDep.
  ///
  /// In en, this message translates to:
  /// **'DEP'**
  String get navFreqDep;

  /// No description provided for @treeNoPlans.
  ///
  /// In en, this message translates to:
  /// **'No flight plans'**
  String get treeNoPlans;

  /// No description provided for @treeCreateHint.
  ///
  /// In en, this message translates to:
  /// **'Click to create one'**
  String get treeCreateHint;

  /// No description provided for @profileTabAltitude.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get profileTabAltitude;

  /// No description provided for @profileTabFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get profileTabFuel;

  /// No description provided for @profileTabSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get profileTabSpeed;

  /// No description provided for @profileTabWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get profileTabWeather;

  /// No description provided for @profileHint.
  ///
  /// In en, this message translates to:
  /// **'Altitude/fuel profile will render here'**
  String get profileHint;

  /// No description provided for @settingsCategoryApiKeys.
  ///
  /// In en, this message translates to:
  /// **'API Keys'**
  String get settingsCategoryApiKeys;

  /// No description provided for @settingsCategoryApiKeysDesc.
  ///
  /// In en, this message translates to:
  /// **'Credentials for map tiles, AI copilot and flight tracking.'**
  String get settingsCategoryApiKeysDesc;

  /// No description provided for @apiKeysSecurityNote.
  ///
  /// In en, this message translates to:
  /// **'Keys are stored locally on this device and never displayed in full after saving.'**
  String get apiKeysSecurityNote;

  /// No description provided for @apiTileProvider.
  ///
  /// In en, this message translates to:
  /// **'Map tile provider'**
  String get apiTileProvider;

  /// No description provided for @apiTileProviderHint.
  ///
  /// In en, this message translates to:
  /// **'Choose where raster map tiles come from. OSM is free and needs no key.'**
  String get apiTileProviderHint;

  /// No description provided for @apiTileProviderOsm.
  ///
  /// In en, this message translates to:
  /// **'OSM'**
  String get apiTileProviderOsm;

  /// No description provided for @apiTileProviderMapboxStreets.
  ///
  /// In en, this message translates to:
  /// **'Mapbox Streets'**
  String get apiTileProviderMapboxStreets;

  /// No description provided for @apiTileProviderMapboxSatellite.
  ///
  /// In en, this message translates to:
  /// **'Mapbox Satellite'**
  String get apiTileProviderMapboxSatellite;

  /// No description provided for @apiTileProviderCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get apiTileProviderCustom;

  /// No description provided for @apiMapboxToken.
  ///
  /// In en, this message translates to:
  /// **'Mapbox access token'**
  String get apiMapboxToken;

  /// No description provided for @apiMapboxTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Get a free token at mapbox.com. Required for Mapbox tile providers.'**
  String get apiMapboxTokenHint;

  /// No description provided for @apiCustomTileUrl.
  ///
  /// In en, this message translates to:
  /// **'Custom tile URL'**
  String get apiCustomTileUrl;

  /// No description provided for @apiCustomTileUrlHint.
  ///
  /// In en, this message translates to:
  /// **'URL template with z/x/y coordinate segments for self-hosted tiles. Use curly braces around z, x, y for dynamic values.'**
  String get apiCustomTileUrlHint;

  /// No description provided for @apiCustomTileUrlPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'https://tiles.example.com/14/8560/12745.png'**
  String get apiCustomTileUrlPlaceholder;

  /// No description provided for @apiFlightAwareKey.
  ///
  /// In en, this message translates to:
  /// **'FlightAware API key'**
  String get apiFlightAwareKey;

  /// No description provided for @apiFlightAwareKeyHint.
  ///
  /// In en, this message translates to:
  /// **'For querying real-world flights and route inspiration.'**
  String get apiFlightAwareKeyHint;

  /// No description provided for @apiKeySet.
  ///
  /// In en, this message translates to:
  /// **'Key set'**
  String get apiKeySet;

  /// No description provided for @apiKeyAdd.
  ///
  /// In en, this message translates to:
  /// **'Add API Key'**
  String get apiKeyAdd;

  /// No description provided for @apiKeyAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add API Key'**
  String get apiKeyAddTitle;

  /// No description provided for @apiKeyType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get apiKeyType;

  /// No description provided for @apiKeyTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Select the type of API credential'**
  String get apiKeyTypeHint;

  /// No description provided for @apiKeyValue.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKeyValue;

  /// No description provided for @apiKeyValueHint.
  ///
  /// In en, this message translates to:
  /// **'Paste your key here. It will be masked after saving.'**
  String get apiKeyValueHint;

  /// No description provided for @apiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Label (optional)'**
  String get apiKeyLabel;

  /// No description provided for @apiKeyLabelHint.
  ///
  /// In en, this message translates to:
  /// **'A name to help you identify this key'**
  String get apiKeyLabelHint;

  /// No description provided for @apiKeyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No API keys stored'**
  String get apiKeyEmpty;

  /// No description provided for @apiKeyEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Click + to add one'**
  String get apiKeyEmptyHint;

  /// No description provided for @apiKeyTypeMapboxToken.
  ///
  /// In en, this message translates to:
  /// **'Mapbox Token'**
  String get apiKeyTypeMapboxToken;

  /// No description provided for @apiKeyTypeOsmToken.
  ///
  /// In en, this message translates to:
  /// **'OSM Tile Token'**
  String get apiKeyTypeOsmToken;

  /// No description provided for @apiKeyTypeAiCopilot.
  ///
  /// In en, this message translates to:
  /// **'AI Copilot Key'**
  String get apiKeyTypeAiCopilot;

  /// No description provided for @apiKeyTypeFlightAware.
  ///
  /// In en, this message translates to:
  /// **'FlightAware Key'**
  String get apiKeyTypeFlightAware;

  /// No description provided for @apiKeyTypeCustomTileUrl.
  ///
  /// In en, this message translates to:
  /// **'Custom Tile URL'**
  String get apiKeyTypeCustomTileUrl;

  /// No description provided for @mapTheme.
  ///
  /// In en, this message translates to:
  /// **'Map Theme'**
  String get mapTheme;

  /// No description provided for @mapProjectionFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat (2D)'**
  String get mapProjectionFlat;

  /// No description provided for @mapProjectionGlobe.
  ///
  /// In en, this message translates to:
  /// **'Globe (3D)'**
  String get mapProjectionGlobe;

  /// No description provided for @mapNetworkRepair.
  ///
  /// In en, this message translates to:
  /// **'Network Repair'**
  String get mapNetworkRepair;

  /// No description provided for @apiKeyConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete this API key?'**
  String get apiKeyConfirmDelete;

  /// No description provided for @apiKeyConfirmDeleteDesc.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get apiKeyConfirmDeleteDesc;

  /// No description provided for @simAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Simulator'**
  String get simAddTitle;

  /// No description provided for @simType.
  ///
  /// In en, this message translates to:
  /// **'Simulator Type'**
  String get simType;

  /// No description provided for @simTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Select the type of simulator'**
  String get simTypeHint;

  /// No description provided for @simInstallPath.
  ///
  /// In en, this message translates to:
  /// **'Install Path'**
  String get simInstallPath;

  /// No description provided for @simInstallPathHint.
  ///
  /// In en, this message translates to:
  /// **'Browse for the simulator root folder'**
  String get simInstallPathHint;

  /// No description provided for @simBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get simBrowse;

  /// No description provided for @simPathPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'D:\\Resources\\Softwares\\X-Plane12'**
  String get simPathPlaceholder;

  /// No description provided for @simValidating.
  ///
  /// In en, this message translates to:
  /// **'Validating'**
  String get simValidating;

  /// No description provided for @simValid.
  ///
  /// In en, this message translates to:
  /// **'Valid install found'**
  String get simValid;

  /// No description provided for @simInvalid.
  ///
  /// In en, this message translates to:
  /// **'X-Plane.exe not found in this folder'**
  String get simInvalid;

  /// No description provided for @simLabel.
  ///
  /// In en, this message translates to:
  /// **'Label (optional)'**
  String get simLabel;

  /// No description provided for @simLabelHint.
  ///
  /// In en, this message translates to:
  /// **'A name to identify this install'**
  String get simLabelHint;

  /// No description provided for @simXplane12.
  ///
  /// In en, this message translates to:
  /// **'X-Plane 12'**
  String get simXplane12;

  /// No description provided for @simMsfs2020.
  ///
  /// In en, this message translates to:
  /// **'MSFS 2020'**
  String get simMsfs2020;

  /// No description provided for @simMsfs2024.
  ///
  /// In en, this message translates to:
  /// **'MSFS 2024'**
  String get simMsfs2024;

  /// No description provided for @simPrepar3dV4.
  ///
  /// In en, this message translates to:
  /// **'Prepar3D v4'**
  String get simPrepar3dV4;

  /// No description provided for @simPrepar3dV5.
  ///
  /// In en, this message translates to:
  /// **'Prepar3D v5'**
  String get simPrepar3dV5;

  /// No description provided for @simPrepar3dV6.
  ///
  /// In en, this message translates to:
  /// **'Prepar3D v6'**
  String get simPrepar3dV6;

  /// No description provided for @simComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon — supported in a future phase'**
  String get simComingSoon;

  /// No description provided for @simEmpty.
  ///
  /// In en, this message translates to:
  /// **'No simulators added'**
  String get simEmpty;

  /// No description provided for @simEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Click + to add one'**
  String get simEmptyHint;

  /// No description provided for @navAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Navigation Data Source'**
  String get navAddTitle;

  /// No description provided for @navSelectSimulator.
  ///
  /// In en, this message translates to:
  /// **'Select Simulator'**
  String get navSelectSimulator;

  /// No description provided for @navNoSimulator.
  ///
  /// In en, this message translates to:
  /// **'No simulator found. Please add a simulator first.'**
  String get navNoSimulator;

  /// No description provided for @navDataType.
  ///
  /// In en, this message translates to:
  /// **'Data Type'**
  String get navDataType;

  /// No description provided for @navDefaultData.
  ///
  /// In en, this message translates to:
  /// **'Default Data'**
  String get navDefaultData;

  /// No description provided for @navCustomData.
  ///
  /// In en, this message translates to:
  /// **'Custom Data'**
  String get navCustomData;

  /// No description provided for @navCustomPath.
  ///
  /// In en, this message translates to:
  /// **'Custom Data Path'**
  String get navCustomPath;

  /// No description provided for @navScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get navScan;

  /// No description provided for @navScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning'**
  String get navScanning;

  /// No description provided for @navEmpty.
  ///
  /// In en, this message translates to:
  /// **'No navigation data sources'**
  String get navEmpty;

  /// No description provided for @navEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Click + to add one'**
  String get navEmptyHint;

  /// No description provided for @simInvalidNotFound.
  ///
  /// In en, this message translates to:
  /// **'{exe} not found in this folder'**
  String simInvalidNotFound(String exe);

  /// No description provided for @simConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Remove this simulator?'**
  String get simConfirmDelete;

  /// No description provided for @simConfirmDeleteDesc.
  ///
  /// In en, this message translates to:
  /// **'Associated navdata sources will also be removed.'**
  String get simConfirmDeleteDesc;

  /// No description provided for @navConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Remove this navdata source?'**
  String get navConfirmDelete;

  /// No description provided for @navConfirmDeleteDesc.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get navConfirmDeleteDesc;

  /// No description provided for @navCheckAll.
  ///
  /// In en, this message translates to:
  /// **'Check All Navdata'**
  String get navCheckAll;

  /// No description provided for @legendAirport.
  ///
  /// In en, this message translates to:
  /// **'Airport'**
  String get legendAirport;

  /// No description provided for @legendVor.
  ///
  /// In en, this message translates to:
  /// **'VOR'**
  String get legendVor;

  /// No description provided for @legendVordme.
  ///
  /// In en, this message translates to:
  /// **'VOR/DME'**
  String get legendVordme;

  /// No description provided for @legendVortac.
  ///
  /// In en, this message translates to:
  /// **'VORTAC'**
  String get legendVortac;

  /// No description provided for @legendTacan.
  ///
  /// In en, this message translates to:
  /// **'TACAN'**
  String get legendTacan;

  /// No description provided for @legendDme.
  ///
  /// In en, this message translates to:
  /// **'DME'**
  String get legendDme;

  /// No description provided for @legendNdb.
  ///
  /// In en, this message translates to:
  /// **'NDB'**
  String get legendNdb;

  /// No description provided for @legendWaypoint.
  ///
  /// In en, this message translates to:
  /// **'Waypoint'**
  String get legendWaypoint;

  /// No description provided for @legendIls.
  ///
  /// In en, this message translates to:
  /// **'ILS'**
  String get legendIls;

  /// No description provided for @legendGs.
  ///
  /// In en, this message translates to:
  /// **'GS'**
  String get legendGs;

  /// No description provided for @legendMarker.
  ///
  /// In en, this message translates to:
  /// **'Marker'**
  String get legendMarker;

  /// No description provided for @panelSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get panelSearch;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search airports, navaids, waypoints…'**
  String get searchHint;

  /// No description provided for @searchStart.
  ///
  /// In en, this message translates to:
  /// **'Start typing to search'**
  String get searchStart;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get searchNoResults;
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

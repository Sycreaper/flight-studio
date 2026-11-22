// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Flight Studio';

  @override
  String get navRecentFlights => 'Start';

  @override
  String get navPluginCenter => 'Plugin Center';

  @override
  String get navSettings => 'Settings';

  @override
  String get createFirstFlight => 'Create your first flight';

  @override
  String get createFlight => 'Create Flight';

  @override
  String get worldMap => 'World Map';

  @override
  String get flightAcademy => 'Flight Academy';

  @override
  String get searchFlights => 'Search flights…';

  @override
  String get noResults => 'No flights match your search';

  @override
  String get pluginCenterTitle => 'Plugin Center';

  @override
  String get pluginCenterDesc => 'Manage simulator bridges and extensions';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get openSettings => 'Open settings';

  @override
  String get tabMap => 'Map';

  @override
  String get tabFlightPlan => 'Flight Plan';

  @override
  String get tabChat => 'Chat';

  @override
  String get chatNewConversation => 'New chat';

  @override
  String get panelConversations => 'Conversations';

  @override
  String get conversationNew => 'New conversation';

  @override
  String get conversationEmpty => 'No conversations yet';

  @override
  String get conversationDelete => 'Delete conversation';

  @override
  String get conversationDeleteConfirm =>
      'Delete this conversation? This cannot be undone.';

  @override
  String get conversationDeleteAction => 'Delete';

  @override
  String get conversationExport => 'Export conversation';

  @override
  String get conversationApprovalLog => 'Permission log';

  @override
  String get approvalLogTitle => 'Permission log';

  @override
  String get approvalLogEmpty =>
      'No tool-permission decisions in this conversation yet';

  @override
  String get approvalLogLoadFailed =>
      'Permission log unavailable — is the gateway running?';

  @override
  String get approvalOutcomeApproved => 'Approved';

  @override
  String get approvalOutcomeDenied => 'Denied';

  @override
  String get approvalOutcomeDeniedTimeout => 'Denied (timeout)';

  @override
  String get approvalOutcomeAutoAllowed => 'Auto-allowed';

  @override
  String get approvalOutcomePolicyDenied => 'Blocked by policy';

  @override
  String get approvalOutcomeSilentAllowed => 'Skill (always allowed)';

  @override
  String get approvalOutcomeFailClosed => 'Fail-closed';

  @override
  String get approvalRevealTooltip => 'Jump to context';

  @override
  String approvalLevelTooltip(Object level) {
    return 'Access level granted for this turn: $level';
  }

  @override
  String get conversationExportUser => 'User';

  @override
  String get conversationExportAssistant => 'Flight Assistant';

  @override
  String get conversationExportDone => 'Exported';

  @override
  String get approvalResolvedAllow => 'Approved';

  @override
  String get approvalResolvedDeny => 'Denied';

  @override
  String get approvalAutoAllowed => 'Auto-allowed';

  @override
  String get approvalAutoDenied => 'Auto-denied';

  @override
  String get aiLevelChipLabel =>
      'AI access level (L0–L3) — L0 confirms every tool call; L1+ auto-runs data reads; writes and other tools need confirmation; Bash commands are always denied; skills always run';

  @override
  String get aiLevel0 => 'L0 · Manual confirm';

  @override
  String get aiLevel1 => 'L1 · Auto data';

  @override
  String get aiLevel2 => 'L2 · Reserved';

  @override
  String get aiLevel3 => 'L3 · Reserved';

  @override
  String get tabMapUnnamed => 'Map';

  @override
  String get tabPlanUnnamed => 'Flight Plan';

  @override
  String get addTab => 'Add tab';

  @override
  String get newMapTab => 'New Map';

  @override
  String get newFlightPlanTab => 'New Flight Plan';

  @override
  String get closeTab => 'Close tab';

  @override
  String get noOpenTabs => 'No open tabs';

  @override
  String get clickPlusToOpen => 'Click the + on the right to open a new tab';

  @override
  String get sectionFlightInfo => 'Flight Information';

  @override
  String get sectionRoute => 'Route';

  @override
  String get sectionPerformance => 'Fuel & Performance';

  @override
  String get sectionProcedures => 'Procedures';

  @override
  String get fieldAircraft => 'Aircraft';

  @override
  String get fieldAirframe => 'Airframe / Registration';

  @override
  String get fieldAirline => 'Airline';

  @override
  String get fieldFlightNumber => 'Flight Number';

  @override
  String get fieldCallsign => 'Callsign';

  @override
  String get fieldDeparture => 'Departure (ICAO)';

  @override
  String get fieldDestination => 'Destination (ICAO)';

  @override
  String get fieldAlternate => 'Alternate (ICAO)';

  @override
  String get fieldCruiseLevel => 'Cruise Level (FL)';

  @override
  String get fieldCostIndex => 'Cost Index';

  @override
  String get fieldRoute => 'Route string';

  @override
  String get fieldContingency => 'Contingency fuel';

  @override
  String get fieldReserve => 'Reserve fuel';

  @override
  String get fieldTaxiFuel => 'Taxi fuel';

  @override
  String get fieldExtraFuel => 'Extra fuel';

  @override
  String get fieldUnits => 'Units';

  @override
  String get fieldSid => 'SID';

  @override
  String get fieldStar => 'STAR';

  @override
  String get fieldApproach => 'Approach';

  @override
  String get fieldPlanDetail => 'Plan detail';

  @override
  String get unitsKg => 'Kilograms';

  @override
  String get unitsLb => 'Pounds';

  @override
  String get detailFull => 'Detailed';

  @override
  String get detailRouteOnly => 'Route Only';

  @override
  String get calculatePlan => 'Calculate Plan';

  @override
  String get resetForm => 'Reset';

  @override
  String get settingsResetDefaults => 'Reset to defaults';

  @override
  String get settingsResetDefaultsConfirm =>
      'Reset all settings to their defaults? This cannot be undone.';

  @override
  String get settingsReset => 'Reset';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsClose => 'Close';

  @override
  String get settingsSave => 'Save';

  @override
  String get settingsEdit => 'Edit';

  @override
  String get settingsBrowse => 'Browse…';

  @override
  String get settingsNotSet => 'Not set';

  @override
  String get settingsPlannedBadge => 'Planned';

  @override
  String get settingsConnectedBadge => 'Connected';

  @override
  String get settingsDisconnectedBadge => 'Disconnected';

  @override
  String get gearMenuTooltip => 'Open menu';

  @override
  String get gearMenuSettings => 'Settings…';

  @override
  String get gearMenuAbout => 'About Flight Studio';

  @override
  String get gearMenuCheckUpdates => 'Check for Updates…';

  @override
  String get gearMenuCheckUpdatesNone => 'You are running the latest version.';

  @override
  String get gearMenuHelp => 'Help';

  @override
  String get gearMenuExit => 'Exit';

  @override
  String get toolbarHome => 'Back to welcome';

  @override
  String get aboutDialogTitle => 'About Flight Studio';

  @override
  String get settingsCategoryGeneral => 'General';

  @override
  String get settingsCategoryData => 'Data';

  @override
  String get settingsCategorySimulator => 'Simulator';

  @override
  String get settingsCategoryNavdata => 'Navigation Data';

  @override
  String get settingsCategoryAi => 'AI Copilot';

  @override
  String get settingsCategoryAbout => 'About';

  @override
  String get settingsAppearanceTitle => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get languageSystem => 'Follow system';

  @override
  String get settingsFontFamily => 'Interface font';

  @override
  String get settingsFontDefault => 'Default';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'Follow system';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsLanguageZh => '中文（简体）';

  @override
  String get settingsStartupTitle => 'Startup';

  @override
  String get settingsReopenLastWorkspace => 'Reopen last workspace on launch';

  @override
  String get settingsCheckUpdatesOnLaunch => 'Check for updates on launch';

  @override
  String get settingsUnitsTitle => 'Default units';

  @override
  String get settingsUnitsMetric => 'Metric (kg, km)';

  @override
  String get settingsUnitsImperial => 'Imperial (lb, nm)';

  @override
  String get settingsSimulatorTitle => 'Simulator connections';

  @override
  String get settingsXplaneTitle => 'X-Plane 12';

  @override
  String settingsXplaneStatusConnected(int port) {
    return 'Bridge detected on port $port';
  }

  @override
  String get settingsXplaneStatusDisconnected => 'Not connected';

  @override
  String get settingsXplaneInstallPath => 'X-Plane install folder';

  @override
  String get settingsXplaneInstallPick => 'Choose folder…';

  @override
  String get settingsXplaneInstallClear => 'Clear';

  @override
  String get settingsXplaneUdpPort => 'Telemetry UDP port';

  @override
  String get settingsXplaneBridgePort => 'Bridge command port';

  @override
  String get settingsXplaneInstallBridge => 'Install FlyWithLua bridge…';

  @override
  String get settingsXplaneTestConnection => 'Test connection';

  @override
  String get settingsMsfsTitle => 'MSFS 2020 / 2024 & Prepar3D';

  @override
  String get settingsMsfsPlanned =>
      'The C++ SimConnect bridge daemon is planned for a later phase. Telemetry and command support for MSFS and Prepar3D will share this adapter.';

  @override
  String get settingsMsfsBridgePath => 'SimConnect bridge daemon';

  @override
  String get settingsNavdataTitle => 'Navigation data sources';

  @override
  String get settingsNavdataBundledTitle => 'Bundled (free & open)';

  @override
  String get settingsNavdataOurAirports => 'OurAirports';

  @override
  String get settingsNavdataFaaCifp => 'FAA CIFP / NASR';

  @override
  String get settingsNavdataXplaneNative => 'Parse X-Plane native files';

  @override
  String get settingsNavdataRefreshBundled => 'Refresh bundled data';

  @override
  String get settingsNavdataNavigraphTitle => 'Navigraph (user subscription)';

  @override
  String settingsNavdataNavigraphSignedIn(String user) {
    return 'Signed in as $user';
  }

  @override
  String get settingsNavdataNavigraphSignedOut => 'Not signed in';

  @override
  String get settingsNavdataNavigraphSignIn => 'Sign in with Navigraph…';

  @override
  String get settingsNavdataNavigraphSignOut => 'Sign out';

  @override
  String get settingsNavdataNavigraphAirac => 'Active AIRAC cycle';

  @override
  String get settingsNavdataNavigraphAiracNone => 'Not available';

  @override
  String get settingsNavdataSimBriefTitle => 'SimBrief (free account)';

  @override
  String settingsNavdataSimBriefLinked(String username) {
    return 'Linked to $username';
  }

  @override
  String get settingsNavdataSimBriefNotLinked => 'Not linked';

  @override
  String get settingsNavdataSimBriefLink => 'Link SimBrief account…';

  @override
  String get settingsNavdataSimBriefUnlink => 'Unlink';

  @override
  String get settingsAiTitle => 'AI Copilot';

  @override
  String get settingsAiProvider => 'Provider';

  @override
  String get settingsAiProviderOpenAi => 'OpenAI-compatible';

  @override
  String get settingsAiProviderAnthropic => 'Anthropic';

  @override
  String get settingsAiProviderOllama => 'Local (Ollama)';

  @override
  String get settingsAiApiKey => 'API key';

  @override
  String get settingsAiApiKeyHidden => 'Key set (hidden)';

  @override
  String get settingsAiEndpoint => 'Endpoint URL';

  @override
  String get settingsAiEndpointPlaceholder => 'https://api.openai.com/v1';

  @override
  String get settingsAiModel => 'Model';

  @override
  String get settingsAiModelPlaceholder => 'model-id';

  @override
  String get settingsReasoningEffort => 'Reasoning effort';

  @override
  String get settingsAiModelService => 'Model service';

  @override
  String get aiLettaRuntimeTitle => 'Letta CLI (local agent runtime)';

  @override
  String get aiLettaChecking => 'Checking environment…';

  @override
  String get aiLettaNotInstalledTitle => 'Letta CLI is not installed';

  @override
  String get aiLettaInstalledTitle => 'Letta CLI is installed';

  @override
  String get aiLettaNodeMissingTitle => 'Node.js not found';

  @override
  String get aiLettaNodeTooOldTitle => 'Node.js version too old';

  @override
  String aiLettaNodeDetected(String version) {
    return 'Detected Node.js $version';
  }

  @override
  String get aiLettaNodeRequiredHint =>
      'The Letta CLI requires Node.js 22.19 or newer (distributed via npm).';

  @override
  String get aiLettaNodeDownload => 'Open Node.js download page';

  @override
  String get aiLettaRecheck => 'Re-check';

  @override
  String get aiLettaInstall => 'Install';

  @override
  String get aiLettaUninstall => 'Uninstall';

  @override
  String get aiLettaInstalling => 'Installing Letta CLI…';

  @override
  String get aiLettaUninstalling => 'Uninstalling Letta CLI…';

  @override
  String get aiLettaInstallFailed => 'Install failed';

  @override
  String get aiLettaUninstallFailed => 'Uninstall failed';

  @override
  String get aiLettaLog => 'Output log';

  @override
  String get aiLettaUninstallConfirmTitle => 'Uninstall Letta CLI?';

  @override
  String get aiLettaUninstallConfirmDesc =>
      'This only removes the Letta CLI program. Your local accounts and long-term memory data (~/.letta) are not deleted.';

  @override
  String get settingsAiClearApiKey => 'Clear';

  @override
  String get settingsAboutTitle => 'About Flight Studio';

  @override
  String get settingsAboutVersion => 'Version';

  @override
  String get settingsAboutLicense => 'License';

  @override
  String get settingsAboutLicenseValue =>
      'MIT — permissive, clean-room reimplementation';

  @override
  String get settingsAboutViewLicense => 'View full license';

  @override
  String get settingsAboutThirdParty => 'Third-party data';

  @override
  String get settingsAboutThirdPartyDesc =>
      'Navigraph and SimBrief data is user-licensed and never redistributed. OpenStreetMap tiles are © OSM contributors (ODbL). OurAirports and FAA CIFP/NASR are Public Domain.';

  @override
  String get settingsAboutViewThirdParty => 'View third-party notices';

  @override
  String get settingsAboutHomepage => 'Homepage';

  @override
  String get settingsAboutOpenSource => 'Open source on GitHub';

  @override
  String get settingsAboutInspiredBy =>
      'Inspired by Little Navmap (no GPL source reused).';

  @override
  String get tabSettings => 'Settings';

  @override
  String get welcomeSubtitle => 'AI flight agent workbench';

  @override
  String get ttNewFlightPlan => 'New flight plan';

  @override
  String get ttOpenFlightPlan => 'Open flight plan';

  @override
  String get ttExport => 'Export';

  @override
  String get ttCalculateRoute => 'Calculate route';

  @override
  String get ttConnectSim => 'Connect simulator';

  @override
  String get ttPauseSim => 'Pause simulator';

  @override
  String get ttToggleProjection => 'Toggle projection';

  @override
  String get ttCalculatePlan => 'Calculate plan';

  @override
  String get ttResetForm => 'Reset form';

  @override
  String get ttImportRoute => 'Import route';

  @override
  String get ttExportPlan => 'Export plan';

  @override
  String get ttFetchSimBrief => 'Fetch from SimBrief';

  @override
  String get ttSavePlan => 'Save plan';

  @override
  String get mapPlaceholder => 'Map';

  @override
  String get mapApiKeyCta => 'Bind your map API key to enable live tiles';

  @override
  String get mapLoadError => 'Map failed to load';

  @override
  String get mapErrorNoNetwork =>
      'No network connection — check your internet and retry.';

  @override
  String get mapError404 =>
      'Tile server returned 404. The tile URL may be incorrect or the server is down.';

  @override
  String mapErrorGeneric(String code) {
    return 'Error $code';
  }

  @override
  String get mapRetry => 'Retry';

  @override
  String get mapZoomIn => 'Zoom in';

  @override
  String get mapZoomOut => 'Zoom out';

  @override
  String get statusConnected => 'Connected';

  @override
  String get statusDisconnected => 'Disconnected';

  @override
  String get statusNoNavdata => 'No navdata loaded';

  @override
  String get statusCpu => 'CPU';

  @override
  String get statusGpu => 'GPU';

  @override
  String get statusMem => 'MEM';

  @override
  String get panelFlightPlans => 'Flight Plans';

  @override
  String get panelInspector => 'Inspector';

  @override
  String get panelProfile => 'Profile';

  @override
  String get hidePanel => 'Hide';

  @override
  String get inspectorHint =>
      'Double-click a map icon or a search result to see its details here.';

  @override
  String get inspectorType => 'Type';

  @override
  String get inspectorCoordinates => 'Coordinates';

  @override
  String get inspectorElevation => 'Elevation';

  @override
  String get inspectorFrequency => 'Frequency';

  @override
  String get inspectorRunways => 'Runways';

  @override
  String get inspectorIata => 'IATA';

  @override
  String get inspectorCity => 'City';

  @override
  String get inspectorFlyTo => 'Fly to this point';

  @override
  String get inspectorClear => 'Clear inspector';

  @override
  String get inspectorFrequencies => 'ATC Frequencies';

  @override
  String get inspectorWeather => 'Weather';

  @override
  String get inspectorWeatherUnavailable =>
      'No weather available for this station.';

  @override
  String get inspectorTabOverview => 'Overview';

  @override
  String get inspectorTabComms => 'Comms';

  @override
  String get inspectorIcao => 'ICAO';

  @override
  String get inspectorXplaneIdent => 'X-Plane ident';

  @override
  String get inspectorRegion => 'Region';

  @override
  String get inspectorCountry => 'Country/region code';

  @override
  String get inspectorMagvar => 'Magnetic declination';

  @override
  String get inspectorSunTimes => 'Sunrise & sunset';

  @override
  String get inspectorNotAvailable => '—';

  @override
  String get inspectorRawReport => 'Raw report';

  @override
  String get inspectorWindCalm => 'Calm';

  @override
  String get splashStarting => 'Starting Flight Studio';

  @override
  String get splashScanning => 'Scanning navigation data…';

  @override
  String get splashNoNavdata => 'No navigation data found';

  @override
  String get settingsSplash => 'Splash screen';

  @override
  String get settingsSplashScan => 'Auto-scan navigation data on startup';

  @override
  String get splashScanAlways => 'Always';

  @override
  String get splashScanAfter14 => 'Last scan over 14 days ago';

  @override
  String get splashScanAfter28 => 'Last scan over 28 days ago';

  @override
  String get splashScanNever => 'Never';

  @override
  String get navActiveSource => 'ACTIVE';

  @override
  String get inspectorDataSource => 'Data source';

  @override
  String get inspectorRunwayCount => 'Runways';

  @override
  String get inspectorLongestRunway => 'Longest runway';

  @override
  String get airportTypeAirport => 'Airport';

  @override
  String get airportTypeHeliport => 'Heliport';

  @override
  String get airportTypeSeaplane => 'Seaplane';

  @override
  String get navFreqAtis => 'ATIS';

  @override
  String get navFreqCtaf => 'CTAF';

  @override
  String get navFreqGnd => 'GND';

  @override
  String get navFreqTwr => 'TWR';

  @override
  String get navFreqCld => 'CLD';

  @override
  String get navFreqApp => 'APP';

  @override
  String get navFreqDep => 'DEP';

  @override
  String get treeNoPlans => 'No flight plans';

  @override
  String get treeCreateHint => 'Click to create one';

  @override
  String get profileTabAltitude => 'Altitude';

  @override
  String get profileTabFuel => 'Fuel';

  @override
  String get profileTabSpeed => 'Speed';

  @override
  String get profileTabWeather => 'Weather';

  @override
  String get profileHint => 'Altitude/fuel profile will render here';

  @override
  String get settingsCategoryApiKeys => 'API Keys';

  @override
  String get apiKeysSecurityNote =>
      'Keys are stored locally on this device and never displayed in full after saving.';

  @override
  String get apiTileProvider => 'Map tile provider';

  @override
  String get apiTileProviderOsm => 'OSM';

  @override
  String get apiTileProviderMapboxStreets => 'Mapbox Streets';

  @override
  String get apiTileProviderMapboxSatellite => 'Mapbox Satellite';

  @override
  String get apiTileProviderCustom => 'Custom';

  @override
  String get apiMapboxToken => 'Mapbox access token';

  @override
  String get apiCustomTileUrl => 'Custom tile URL';

  @override
  String get apiCustomTileUrlPlaceholder =>
      'https://tiles.example.com/14/8560/12745.png';

  @override
  String get apiFlightAwareKey => 'FlightAware API key';

  @override
  String get apiKeySet => 'Key set';

  @override
  String get apiKeyAdd => 'Add API Key';

  @override
  String get apiKeyAddTitle => 'Add API Key';

  @override
  String get apiKeyType => 'Type';

  @override
  String get apiKeyValue => 'API Key';

  @override
  String get apiKeyValueHint =>
      'Paste your key here. It will be masked after saving.';

  @override
  String get apiKeyLabel => 'Label (optional)';

  @override
  String get apiKeyLabelHint => 'A name to help you identify this key';

  @override
  String get apiKeyEmpty => 'No API keys stored';

  @override
  String get apiKeyEmptyHint => 'Click + to add one';

  @override
  String get apiKeyTypeMapboxToken => 'Mapbox Token';

  @override
  String get apiKeyTypeOsmToken => 'OSM Tile Token';

  @override
  String get startHeroTitle => 'Ready when you are';

  @override
  String get startPromptHint => 'Ask anything';

  @override
  String get startSend => 'Send';

  @override
  String get apiKeyTypeFlightAware => 'FlightAware Key';

  @override
  String get apiKeyTypeAiCopilot => 'AI Copilot Key';

  @override
  String get apiKeyTypeOpenAiCompatible => 'OpenAI-compatible API Key';

  @override
  String get openAiProvider => 'Provider';

  @override
  String get openAiProviderGlm => 'GLM (non-coding plan)';

  @override
  String get openAiProviderQwen => 'Qwen (Tongyi)';

  @override
  String get openAiProviderDeepseek => 'DeepSeek';

  @override
  String get openAiProviderMinimax => 'MiniMax';

  @override
  String get openAiProviderMoonshot => 'Moonshot (Kimi)';

  @override
  String get openAiProviderSiliconflow => 'SiliconFlow';

  @override
  String get openAiProviderOpenrouter => 'OpenRouter';

  @override
  String get openAiProviderCustom => 'Custom';

  @override
  String get openAiBaseUrl => 'Base URL';

  @override
  String get openAiBaseUrlHint => 'https://api.openai.com/v1';

  @override
  String get openAiTest => 'Test';

  @override
  String get openAiTestOk => '✓ Connection successful';

  @override
  String get openAiTestFail => '✗ Connection failed';

  @override
  String get openAiModelsEmpty =>
      'No models — add an OpenAI-compatible key first';

  @override
  String get modelChipLabel => 'Model';

  @override
  String get modelChipNoModel => 'No model set — edit the API key';

  @override
  String get modelChipNoModels => 'No models discovered — re-create this key';

  @override
  String get reasoningNone => 'None';

  @override
  String get reasoningMinimal => 'Minimal';

  @override
  String get reasoningLow => 'Low';

  @override
  String get reasoningMedium => 'Medium';

  @override
  String get reasoningHigh => 'High';

  @override
  String get reasoningXhigh => 'Extra high';

  @override
  String get chatThinking => 'Thinking…';

  @override
  String get phaseThinking => 'Thinking…';

  @override
  String get thinkBlockLabel => 'Reasoning';

  @override
  String get phaseSearching => 'Searching…';

  @override
  String get phaseReading => 'Reading…';

  @override
  String get phaseWriting => 'Writing…';

  @override
  String get phaseTool => 'Using tool';

  @override
  String get phaseWaitingApproval => 'Waiting for your approval…';

  @override
  String get phaseWorking => 'Working…';

  @override
  String get approvalTitle => 'Permission request';

  @override
  String approvalWantsToUse(Object tool) {
    return 'The copilot wants to use \"$tool\".';
  }

  @override
  String get approvalAllow => 'Allow';

  @override
  String get approvalDeny => 'Deny';

  @override
  String get approvalRestored => 'Ended';

  @override
  String get mcpToolAirportData => 'Airport data';

  @override
  String get mcpToolChartsRead => 'Chart lookup';

  @override
  String get mcpToolWeatherRead => 'Weather report';

  @override
  String get mcpToolSearchNavdata => 'Navdata search';

  @override
  String get mcpToolSearchManual => 'Manual search';

  @override
  String get mcpToolSimState => 'Simulator state';

  @override
  String get mcpToolActionPlan => 'Action plan proposal';

  @override
  String get mcpToolRenderMap => 'Map rendering';

  @override
  String get mcpToolSetComFrequency => 'Set COM frequency';

  @override
  String get mcpToolSendSimCommand => 'Send simulator command';

  @override
  String get aiDeleteLettaData => 'Delete Letta data';

  @override
  String get aiDeleteLettaDataDesc =>
      'This permanently deletes ALL Letta data — agents, conversations, long-term memory and stored provider keys (C:\\Users\\<you>\\.letta). This cannot be undone. The copilot re-initializes on the next message.';

  @override
  String get aiDeleteLettaDataFailed =>
      'Failed to delete Letta data — the gateway may still be running; try again.';

  @override
  String get chatCopy => 'Copy';

  @override
  String get chatCopied => 'Copied';

  @override
  String get chatErrNoModel =>
      'No model selected — add an OpenAI-compatible API key in Settings → API Keys, then pick it here.';

  @override
  String get chatErrGateway =>
      'The AI gateway could not start. Install Node.js ≥ 22.19 (Settings → AI can help) and try again.';

  @override
  String get chatErrProvider =>
      'Letta rejected the model connection — check the API key, base URL and model name in Settings → API Keys.';

  @override
  String get openAiModel => 'Model';

  @override
  String get apiKeyTypeCustomTileUrl => 'Custom Tile URL';

  @override
  String get mapTheme => 'Map Theme';

  @override
  String get mapProjectionFlat => 'Flat (2D)';

  @override
  String get mapProjectionGlobe => 'Globe (3D)';

  @override
  String get mapNetworkRepair => 'Network Repair';

  @override
  String get apiKeyConfirmDelete => 'Delete this API key?';

  @override
  String get apiKeyConfirmDeleteDesc => 'This action cannot be undone.';

  @override
  String get simAddTitle => 'Add Simulator';

  @override
  String get simExperimental => 'Experimental';

  @override
  String get simType => 'Simulator Type';

  @override
  String get simInstallPath => 'Install Path';

  @override
  String get simInstallPathHint => 'Browse for the simulator root folder';

  @override
  String get simBrowse => 'Browse';

  @override
  String get simPathPlaceholder => 'D:\\Resources\\Softwares\\X-Plane12';

  @override
  String get simValidating => 'Validating';

  @override
  String get simValid => 'Valid install found';

  @override
  String get simInvalid => 'X-Plane.exe not found in this folder';

  @override
  String get simLabel => 'Label (optional)';

  @override
  String get simLabelHint => 'A name to identify this install';

  @override
  String get simXplane12 => 'X-Plane 12';

  @override
  String get simMsfs2020 => 'MSFS 2020';

  @override
  String get simMsfs2024 => 'MSFS 2024';

  @override
  String get simPrepar3dV4 => 'Prepar3D v4';

  @override
  String get simPrepar3dV5 => 'Prepar3D v5';

  @override
  String get simPrepar3dV6 => 'Prepar3D v6';

  @override
  String get simComingSoon => 'Coming soon — supported in a future phase';

  @override
  String get simEmpty => 'No simulators added';

  @override
  String get simEmptyHint => 'Click + to add one';

  @override
  String get navAddTitle => 'Add Navigation Data Source';

  @override
  String get navSelectSimulator => 'Select Simulator';

  @override
  String get navNoSimulator =>
      'No simulator found. Please add a simulator first.';

  @override
  String get navDataType => 'Data Type';

  @override
  String get navDefaultData => 'Default Data';

  @override
  String get navCustomData => 'Custom Data';

  @override
  String get navCustomPath => 'Custom Data Path';

  @override
  String get navScan => 'Scan';

  @override
  String get navScanning => 'Scanning';

  @override
  String get navEmpty => 'No navigation data sources';

  @override
  String get navEmptyHint => 'Click + to add one';

  @override
  String simInvalidNotFound(String exe) {
    return '$exe not found in this folder';
  }

  @override
  String get simConfirmDelete => 'Remove this simulator?';

  @override
  String get simConfirmDeleteDesc =>
      'Associated navdata sources will also be removed.';

  @override
  String get navConfirmDelete => 'Remove this navdata source?';

  @override
  String get navConfirmDeleteDesc => 'This action cannot be undone.';

  @override
  String get navCheckAll => 'Check All Navdata';

  @override
  String get legendAirport => 'Airport';

  @override
  String get legendVor => 'VOR';

  @override
  String get legendVordme => 'VOR/DME';

  @override
  String get legendVortac => 'VORTAC';

  @override
  String get legendTacan => 'TACAN';

  @override
  String get legendDme => 'DME';

  @override
  String get legendNdb => 'NDB';

  @override
  String get legendWaypoint => 'Waypoint';

  @override
  String get legendIls => 'ILS';

  @override
  String get legendGs => 'GS';

  @override
  String get legendMarker => 'Marker';

  @override
  String get panelSearch => 'Search';

  @override
  String get searchHint => 'Search airports, navaids, waypoints…';

  @override
  String get searchStart => 'Start typing to search';

  @override
  String get searchNoResults => 'No results';
}

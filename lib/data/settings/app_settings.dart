import 'package:flutter/material.dart';

import 'api_key_entry.dart';
import 'settings_enums.dart';
import 'simulator_install.dart';

/// Immutable snapshot of every user-facing setting in Flight Studio.
///
/// The [SettingsController] owns the live copy; widgets read from it and
/// request mutations through the controller. Plain Dart class (no freezed /
/// json_serializable) — matches the rest of Phase 0's view-model style and
/// keeps the settings layer trivially auditable since it never touches the
/// network, file system or simulators.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.localeCode = AppLocaleCode.system,
    this.fontFamily,
    this.reopenLastWorkspace = false,
    this.checkUpdatesOnLaunch = true,
    this.preferMetric = true,
    this.splashEnabled = true,
    this.splashScanMode = SplashScanMode.always,
    this.lastNavdataScanAt,
    this.activeNavdataSourceId,
    this.xplaneInstallPath,
    this.xplaneUdpPort = 49000,
    this.xplaneBridgePort = 49001,
    this.useOurAirports = true,
    this.useFaaCifp = true,
    this.useXplaneNative = true,
    this.navigraphUser,
    this.navigraphAirac,
    this.simbriefUsername,
    this.aiProvider = AiProvider.openAi,
    this.aiEndpoint,
    this.aiModel,
    this.aiConfirmWrites = true,
    this.aiAutoRead = true,
    this.remoteEnabled = false,
    this.remotePort = 48080,
    this.remoteToken = '',
    this.remoteMdns = true,
    this.mapTileProvider = MapTileProvider.osm,
    this.mapTheme = MapTheme.system,
    this.selectedMapApiKeyId,
    this.apiKeys = const [],
    this.simulators = const [],
    this.navdataSources = const [],
  });

  // --- General ---------------------------------------------------------------
  final ThemeMode themeMode;
  final AppLocaleCode localeCode;

  /// User-selected UI font family, or `null` for the platform default.
  /// Applied to both light and dark themes at the [MaterialApp] level.
  final String? fontFamily;
  final bool reopenLastWorkspace;
  final bool checkUpdatesOnLaunch;
  final bool preferMetric;

  /// Whether the startup splash screen (navdata scan) is shown at launch.
  final bool splashEnabled;

  /// When the automatic startup navdata scan should run.
  final SplashScanMode splashScanMode;

  // --- X-Plane 12 ------------------------------------------------------------
  final String? xplaneInstallPath;
  final int xplaneUdpPort;
  final int xplaneBridgePort;

  // --- Navigation data -------------------------------------------------------
  final bool useOurAirports;
  final bool useFaaCifp;
  final bool useXplaneNative;
  final String? navigraphUser;
  final String? navigraphAirac;
  final String? simbriefUsername;

  /// When the last successful navdata import finished (auto-updated after
  /// every import — drives the splash scan thresholds).
  final DateTime? lastNavdataScanAt;

  /// The navdata source the user selected (radio) as the one to import on
  /// startup / "check all". `null` = automatic (first provider-compatible
  /// simulator install wins).
  final String? activeNavdataSourceId;

  // --- AI Copilot (BYOK) -----------------------------------------------------
  final AiProvider aiProvider;
  final String? aiEndpoint;
  final String? aiModel;
  final bool aiConfirmWrites;
  final bool aiAutoRead;

  // --- Remote access ---------------------------------------------------------
  final bool remoteEnabled;
  final int remotePort;
  final String remoteToken;
  final bool remoteMdns;

  // --- Map tiles + API keys --------------------------------------------------
  final MapTileProvider mapTileProvider;
  final MapTheme mapTheme;
  final String? selectedMapApiKeyId;
  final List<ApiKeyEntry> apiKeys;
  final List<SimulatorInstall> simulators;
  final List<NavdataSource> navdataSources;

  /// `true` when Navigraph OAuth2 has produced a signed-in session.
  bool get navigraphSignedIn {
    final user = navigraphUser;
    return user != null && user.isNotEmpty;
  }

  /// `true` when the SimBrief account link is active.
  bool get simbriefLinked {
    final user = simbriefUsername;
    return user != null && user.isNotEmpty;
  }

  // --- API key convenience getters -------------------------------------------
  // These search the [apiKeys] list for the first entry of each type. The
  // downstream consumers (tile provider, LLM client, …) call these instead
  // of touching the list directly.

  String? _firstKey(ApiKeyType type) {
    for (final entry in apiKeys) {
      if (entry.type == type) return entry.value;
    }
    return null;
  }

  String? get firstMapboxToken => _firstKey(ApiKeyType.mapboxToken);

  String? get firstOsmToken => _firstKey(ApiKeyType.osmToken);

  String? get firstCustomTileUrl => _firstKey(ApiKeyType.customTileUrl);

  String? get firstAiKey => _firstKey(ApiKeyType.aiCopilot);

  String? get firstFlightAwareKey => _firstKey(ApiKeyType.flightAware);

  /// `true` when at least one AI Copilot key exists.
  bool get aiConfigured => firstAiKey != null && firstAiKey!.isNotEmpty;

  /// The token/URL actually used by the tile provider factory. If
  /// [selectedMapApiKeyId] points to a valid entry, that entry's value wins.
  /// Otherwise falls back to the first entry matching the current provider.
  String? get activeMapToken {
    if (selectedMapApiKeyId != null) {
      for (final entry in apiKeys) {
        if (entry.id == selectedMapApiKeyId) return entry.value;
      }
    }
    return switch (mapTileProvider) {
      MapTileProvider.osm => firstOsmToken,
      MapTileProvider.mapboxStreets => firstMapboxToken,
      MapTileProvider.mapboxSatellite => firstMapboxToken,
      MapTileProvider.custom => firstCustomTileUrl,
    };
  }

  /// `true` when the current tile provider has everything it needs.
  bool get mapReady {
    final token = activeMapToken;
    return token != null && token.isNotEmpty;
  }

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppLocaleCode? localeCode,
    Object? fontFamily = _sentinel,
    bool? reopenLastWorkspace,
    bool? checkUpdatesOnLaunch,
    bool? preferMetric,
    bool? splashEnabled,
    SplashScanMode? splashScanMode,
    Object? lastNavdataScanAt = _sentinel,
    Object? activeNavdataSourceId = _sentinel,
    Object? xplaneInstallPath = _sentinel,
    Object? navigraphUser = _sentinel,
    Object? navigraphAirac = _sentinel,
    Object? simbriefUsername = _sentinel,
    Object? aiEndpoint = _sentinel,
    Object? aiModel = _sentinel,
    int? xplaneUdpPort,
    int? xplaneBridgePort,
    bool? useOurAirports,
    bool? useFaaCifp,
    bool? useXplaneNative,
    AiProvider? aiProvider,
    bool? aiConfirmWrites,
    bool? aiAutoRead,
    bool? remoteEnabled,
    int? remotePort,
    String? remoteToken,
    bool? remoteMdns,
    MapTileProvider? mapTileProvider,
    MapTheme? mapTheme,
    Object? selectedMapApiKeyId = _sentinel,
    List<ApiKeyEntry>? apiKeys,
    List<SimulatorInstall>? simulators,
    List<NavdataSource>? navdataSources,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      fontFamily: _unwrapNullable<String>(fontFamily, this.fontFamily),
      reopenLastWorkspace: reopenLastWorkspace ?? this.reopenLastWorkspace,
      checkUpdatesOnLaunch: checkUpdatesOnLaunch ?? this.checkUpdatesOnLaunch,
      preferMetric: preferMetric ?? this.preferMetric,
      splashEnabled: splashEnabled ?? this.splashEnabled,
      splashScanMode: splashScanMode ?? this.splashScanMode,
      lastNavdataScanAt: _unwrapNullable<DateTime>(
          lastNavdataScanAt, this.lastNavdataScanAt),
      activeNavdataSourceId: _unwrapNullable<String>(
          activeNavdataSourceId, this.activeNavdataSourceId),
      xplaneInstallPath: _unwrapNullable<String>(
        xplaneInstallPath,
        this.xplaneInstallPath,
      ),
      xplaneUdpPort: xplaneUdpPort ?? this.xplaneUdpPort,
      xplaneBridgePort: xplaneBridgePort ?? this.xplaneBridgePort,
      useOurAirports: useOurAirports ?? this.useOurAirports,
      useFaaCifp: useFaaCifp ?? this.useFaaCifp,
      useXplaneNative: useXplaneNative ?? this.useXplaneNative,
      navigraphUser: _unwrapNullable<String>(navigraphUser, this.navigraphUser),
      navigraphAirac: _unwrapNullable<String>(
        navigraphAirac,
        this.navigraphAirac,
      ),
      simbriefUsername: _unwrapNullable<String>(
        simbriefUsername,
        this.simbriefUsername,
      ),
      aiProvider: aiProvider ?? this.aiProvider,
      aiEndpoint: _unwrapNullable<String>(aiEndpoint, this.aiEndpoint),
      aiModel: _unwrapNullable<String>(aiModel, this.aiModel),
      aiConfirmWrites: aiConfirmWrites ?? this.aiConfirmWrites,
      aiAutoRead: aiAutoRead ?? this.aiAutoRead,
      remoteEnabled: remoteEnabled ?? this.remoteEnabled,
      remotePort: remotePort ?? this.remotePort,
      remoteToken: remoteToken ?? this.remoteToken,
      remoteMdns: remoteMdns ?? this.remoteMdns,
      mapTileProvider: mapTileProvider ?? this.mapTileProvider,
      mapTheme: mapTheme ?? this.mapTheme,
      selectedMapApiKeyId: _unwrapNullable<String>(
          selectedMapApiKeyId, this.selectedMapApiKeyId),
      apiKeys: apiKeys ?? this.apiKeys,
      simulators: simulators ?? this.simulators,
      navdataSources: navdataSources ?? this.navdataSources,
    );
  }

  /// Resolve a nullable field sent through [copyWith]. Passing `null` (instead
  /// of the sentinel) clears the field; omitting the argument keeps the prior
  /// value.
  static T? _unwrapNullable<T>(Object? incoming, T? current) {
    if (identical(incoming, _sentinel)) return current;
    return incoming as T?;
  }

  static const Object _sentinel = Object();
}

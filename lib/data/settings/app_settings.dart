import 'package:flutter/material.dart';

import 'settings_enums.dart';

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
    this.reopenLastWorkspace = false,
    this.checkUpdatesOnLaunch = true,
    this.preferMetric = true,
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
    this.aiApiKey,
    this.aiEndpoint,
    this.aiModel,
    this.aiConfirmWrites = true,
    this.aiAutoRead = true,
    this.remoteEnabled = false,
    this.remotePort = 48080,
    this.remoteToken = '',
    this.remoteMdns = true,
  });

  // --- General ---------------------------------------------------------------
  final ThemeMode themeMode;
  final AppLocaleCode localeCode;
  final bool reopenLastWorkspace;
  final bool checkUpdatesOnLaunch;
  final bool preferMetric;

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

  // --- AI Copilot (BYOK) -----------------------------------------------------
  final AiProvider aiProvider;
  final String? aiApiKey;
  final String? aiEndpoint;
  final String? aiModel;
  final bool aiConfirmWrites;
  final bool aiAutoRead;

  // --- Remote access ---------------------------------------------------------
  final bool remoteEnabled;
  final int remotePort;
  final String remoteToken;
  final bool remoteMdns;

  /// `true` when the user has configured at least one BYOK provider with a key.
  bool get aiConfigured {
    final key = aiApiKey;
    return key != null && key.isNotEmpty;
  }

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

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppLocaleCode? localeCode,
    bool? reopenLastWorkspace,
    bool? checkUpdatesOnLaunch,
    bool? preferMetric,
    Object? xplaneInstallPath = _sentinel,
    Object? navigraphUser = _sentinel,
    Object? navigraphAirac = _sentinel,
    Object? simbriefUsername = _sentinel,
    Object? aiApiKey = _sentinel,
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
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      reopenLastWorkspace: reopenLastWorkspace ?? this.reopenLastWorkspace,
      checkUpdatesOnLaunch: checkUpdatesOnLaunch ?? this.checkUpdatesOnLaunch,
      preferMetric: preferMetric ?? this.preferMetric,
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
      aiApiKey: _unwrapNullable<String>(aiApiKey, this.aiApiKey),
      aiEndpoint: _unwrapNullable<String>(aiEndpoint, this.aiEndpoint),
      aiModel: _unwrapNullable<String>(aiModel, this.aiModel),
      aiConfirmWrites: aiConfirmWrites ?? this.aiConfirmWrites,
      aiAutoRead: aiAutoRead ?? this.aiAutoRead,
      remoteEnabled: remoteEnabled ?? this.remoteEnabled,
      remotePort: remotePort ?? this.remotePort,
      remoteToken: remoteToken ?? this.remoteToken,
      remoteMdns: remoteMdns ?? this.remoteMdns,
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

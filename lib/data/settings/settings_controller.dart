import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_key_entry.dart';
import 'app_settings.dart';
import 'settings_enums.dart';
import 'settings_keys.dart';
import 'simulator_install.dart';

/// Owns the live [AppSettings] snapshot and persists every change to
/// [SharedPreferences].
///
/// Designed for constructor injection — pass an instance into the root widget
/// (matching how the codebase injects [FlightRepository]) and listen via
/// `ListenableBuilder` / `AnimatedBuilder`.
///
/// All mutating methods are async because they hit SharedPreferences, but they
/// update the in-memory snapshot synchronously *before* awaiting the write, so
/// the UI never lags behind the user's click. If a write fails it is logged
/// and swallowed — the in-memory value still wins, so the next session simply
/// re-reads the older persisted value.
class SettingsController extends ChangeNotifier {
  SettingsController({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  AppSettings _value = const AppSettings();
  bool _loaded = false;

  /// The current settings snapshot. Read this from a `ListenableBuilder`
  /// listening to this controller.
  AppSettings get value => _value;

  /// `true` once [load] has completed successfully at least once.
  bool get isLoaded => _loaded;

  /// Reads every persisted key and merges it on top of the [AppSettings]
  /// defaults. Safe to call multiple times; later calls refresh from disk.
  Future<void> load() async {
    final snapshot = await _readAll();
    _value = snapshot;
    _loaded = true;
    notifyListeners();
  }

  /// Resets every key to its [AppSettings] default and clears the persisted
  /// values from disk.
  Future<void> resetToDefaults() async {
    final defaults = const AppSettings();
    _value = defaults;
    await _clearAll();
    notifyListeners();
  }

  // --- Mutators --------------------------------------------------------------

  Future<void> setThemeMode(ThemeMode mode) =>
      _update(themeMode: mode, key: SettingsKeys.themeMode, value: mode.name);

  Future<void> setLocaleCode(AppLocaleCode code) => _update(
    localeCode: code,
    key: SettingsKeys.localeCode,
    value: code.persistedName,
  );

  Future<void> setReopenLastWorkspace(bool v) => _updateBool(
    reopenLastWorkspace: v,
    key: SettingsKeys.reopenLastWorkspace,
    value: v,
  );

  Future<void> setCheckUpdatesOnLaunch(bool v) => _updateBool(
    checkUpdatesOnLaunch: v,
    key: SettingsKeys.checkUpdatesOnLaunch,
    value: v,
  );

  Future<void> setPreferMetric(bool v) =>
      _updateBool(preferMetric: v, key: SettingsKeys.preferMetric, value: v);

  Future<void> setXplaneInstallPath(String? path) => _updateNullableString(
    mutator: (s) => s.copyWith(xplaneInstallPath: path),
    key: SettingsKeys.xplaneInstallPath,
    value: path,
  );

  Future<void> setXplaneUdpPort(int port) => _updateInt(
    mutator: (s) => s.copyWith(xplaneUdpPort: port),
    key: SettingsKeys.xplaneUdpPort,
    value: port,
  );

  Future<void> setXplaneBridgePort(int port) => _updateInt(
    mutator: (s) => s.copyWith(xplaneBridgePort: port),
    key: SettingsKeys.xplaneBridgePort,
    value: port,
  );

  Future<void> setUseOurAirports(bool v) => _updateBool(
    useOurAirports: v,
    key: SettingsKeys.useOurAirports,
    value: v,
  );

  Future<void> setUseFaaCifp(bool v) =>
      _updateBool(useFaaCifp: v, key: SettingsKeys.useFaaCifp, value: v);

  Future<void> setUseXplaneNative(bool v) => _updateBool(
    useXplaneNative: v,
    key: SettingsKeys.useXplaneNative,
    value: v,
  );

  Future<void> setNavigraphUser(String? user) => _updateNullableString(
    mutator: (s) => s.copyWith(navigraphUser: user),
    key: SettingsKeys.navigraphUser,
    value: user,
  );

  Future<void> setNavigraphAirac(String? airac) => _updateNullableString(
    mutator: (s) => s.copyWith(navigraphAirac: airac),
    key: SettingsKeys.navigraphAirac,
    value: airac,
  );

  Future<void> setSimBriefUsername(String? username) => _updateNullableString(
    mutator: (s) => s.copyWith(simbriefUsername: username),
    key: SettingsKeys.simbriefUsername,
    value: username,
  );

  Future<void> setAiProvider(AiProvider provider) => _update(
    aiProvider: provider,
    key: SettingsKeys.aiProvider,
    value: provider.persistedName,
  );

  Future<void> setAiEndpoint(String? endpoint) => _updateNullableString(
    mutator: (s) => s.copyWith(aiEndpoint: endpoint),
    key: SettingsKeys.aiEndpoint,
    value: endpoint,
  );

  Future<void> setAiModel(String? model) => _updateNullableString(
    mutator: (s) => s.copyWith(aiModel: model),
    key: SettingsKeys.aiModel,
    value: model,
  );

  Future<void> setAiConfirmWrites(bool v) => _updateBool(
    aiConfirmWrites: v,
    key: SettingsKeys.aiConfirmWrites,
    value: v,
  );

  Future<void> setAiAutoRead(bool v) =>
      _updateBool(aiAutoRead: v, key: SettingsKeys.aiAutoRead, value: v);

  Future<void> setRemoteEnabled(bool v) =>
      _updateBool(remoteEnabled: v, key: SettingsKeys.remoteEnabled, value: v);

  Future<void> setRemotePort(int port) => _updateInt(
    mutator: (s) => s.copyWith(remotePort: port),
    key: SettingsKeys.remotePort,
    value: port,
  );

  Future<void> setRemoteToken(String token) =>
      _update(remoteToken: token, key: SettingsKeys.remoteToken, value: token);

  Future<void> setRemoteMdns(bool v) =>
      _updateBool(remoteMdns: v, key: SettingsKeys.remoteMdns, value: v);

  // --- Map tiles + API keys --------------------------------------------------

  Future<void> setMapTileProvider(MapTileProvider provider) =>
      _update(
        mapTileProvider: provider,
        key: SettingsKeys.mapTileProvider,
        value: provider.persistedName,
      );

  Future<void> setMapTheme(MapTheme theme) =>
      _update(
        mapTheme: theme,
        key: SettingsKeys.mapTheme,
        value: theme.persistedName,
      );

  /// Atomically selects a specific API key entry for map tiles — sets both
  /// [AppSettings.selectedMapApiKeyId] and [AppSettings.mapTileProvider].
  Future<void> selectMapApiKey(String entryId, MapTileProvider provider) async {
    _value = _value.copyWith(
      selectedMapApiKeyId: entryId,
      mapTileProvider: provider,
    );
    notifyListeners();
    await _prefs.setString(SettingsKeys.selectedMapApiKeyId, entryId);
    await _persist(SettingsKeys.mapTileProvider, provider.persistedName);
  }

  // --- API keys (dynamic list) ----------------------------------------------

  /// Adds a new API key entry and persists the full list.
  Future<void> addApiKey(ApiKeyType type, String value, {String? label}) async {
    final entry = ApiKeyEntry(
      id: ApiKeyEntry.generateId(),
      type: type,
      value: value,
      label: label,
    );
    final updated = [..._value.apiKeys, entry];
    _value = _value.copyWith(apiKeys: updated);
    notifyListeners();
    await _persistApiKeys(updated);
  }

  /// Removes the API key entry with [id] and persists the list.
  Future<void> removeApiKey(String id) async {
    final updated = _value.apiKeys.where((e) => e.id != id).toList();
    _value = _value.copyWith(apiKeys: updated);
    notifyListeners();
    await _persistApiKeys(updated);
  }

  Future<void> _persistApiKeys(List<ApiKeyEntry> entries) async {
    try {
      await _prefs.setString(
        SettingsKeys.apiKeys,
        ApiKeyEntry.encodeList(entries),
      );
    } on Exception catch (_) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('SettingsController: failed to persist API keys');
      }
    }
  }

  // --- Simulator installs (dynamic list) -------------------------------------

  Future<void> addSimulator(SimulatorType type, String path,
      {String? name}) async {
    final entry = SimulatorInstall(
      id: SimulatorInstall.generateId(),
      type: type,
      path: path,
      name: name,
    );
    final updated = [..._value.simulators, entry];
    _value = _value.copyWith(simulators: updated);
    notifyListeners();
    await _persistJsonList(
        SettingsKeys.simulators, SimulatorInstall.encodeList(updated));
  }

  Future<void> removeSimulator(String id) async {
    final updated = _value.simulators.where((e) => e.id != id).toList();
    _value = _value.copyWith(simulators: updated);
    notifyListeners();
    await _persistJsonList(
        SettingsKeys.simulators, SimulatorInstall.encodeList(updated));
  }

  // --- Navdata sources (dynamic list) ----------------------------------------

  Future<void> addNavdataSource(String simulatorId, NavdataDataType dataType,
      {String? customPath}) async {
    final entry = NavdataSource(
      id: NavdataSource.generateId(),
      simulatorId: simulatorId,
      dataType: dataType,
      customDataPath: customPath,
    );
    final updated = [..._value.navdataSources, entry];
    _value = _value.copyWith(navdataSources: updated);
    notifyListeners();
    await _persistJsonList(
        SettingsKeys.navdataSources, NavdataSource.encodeList(updated));
  }

  Future<void> removeNavdataSource(String id) async {
    final updated = _value.navdataSources.where((e) => e.id != id).toList();
    _value = _value.copyWith(navdataSources: updated);
    notifyListeners();
    await _persistJsonList(
        SettingsKeys.navdataSources, NavdataSource.encodeList(updated));
  }

  Future<void> _persistJsonList(String key, String json) async {
    try {
      await _prefs.setString(key, json);
    } on Exception catch (_) {
      if (kDebugMode) print('SettingsController: failed to persist $key');
    }
  }

  // --- Internal helpers ------------------------------------------------------

  Future<void> _update({
    ThemeMode? themeMode,
    AppLocaleCode? localeCode,
    AiProvider? aiProvider,
    MapTileProvider? mapTileProvider,
    MapTheme? mapTheme,
    bool? reopenLastWorkspace,
    bool? checkUpdatesOnLaunch,
    bool? preferMetric,
    bool? useOurAirports,
    bool? useFaaCifp,
    bool? useXplaneNative,
    bool? aiConfirmWrites,
    bool? aiAutoRead,
    bool? remoteEnabled,
    String? remoteToken,
    bool? remoteMdns,
    required String key,
    required Object? value,
  }) async {
    _value = _value.copyWith(
      themeMode: themeMode,
      localeCode: localeCode,
      aiProvider: aiProvider,
      mapTileProvider: mapTileProvider,
      mapTheme: mapTheme,
      reopenLastWorkspace: reopenLastWorkspace,
      checkUpdatesOnLaunch: checkUpdatesOnLaunch,
      preferMetric: preferMetric,
      useOurAirports: useOurAirports,
      useFaaCifp: useFaaCifp,
      useXplaneNative: useXplaneNative,
      aiConfirmWrites: aiConfirmWrites,
      aiAutoRead: aiAutoRead,
      remoteEnabled: remoteEnabled,
      remoteToken: remoteToken,
      remoteMdns: remoteMdns,
    );
    notifyListeners();
    await _persist(key, value);
  }

  Future<void> _updateBool({
    bool? reopenLastWorkspace,
    bool? checkUpdatesOnLaunch,
    bool? preferMetric,
    bool? useOurAirports,
    bool? useFaaCifp,
    bool? useXplaneNative,
    bool? aiConfirmWrites,
    bool? aiAutoRead,
    bool? remoteEnabled,
    bool? remoteMdns,
    required String key,
    required bool value,
  }) => _update(
    reopenLastWorkspace: reopenLastWorkspace,
    checkUpdatesOnLaunch: checkUpdatesOnLaunch,
    preferMetric: preferMetric,
    useOurAirports: useOurAirports,
    useFaaCifp: useFaaCifp,
    useXplaneNative: useXplaneNative,
    aiConfirmWrites: aiConfirmWrites,
    aiAutoRead: aiAutoRead,
    remoteEnabled: remoteEnabled,
    remoteMdns: remoteMdns,
    key: key,
    value: value,
  );

  Future<void> _updateInt({
    required AppSettings Function(AppSettings) mutator,
    required String key,
    required int value,
  }) async {
    _value = mutator(_value);
    notifyListeners();
    await _persist(key, value);
  }

  Future<void> _updateNullableString({
    required AppSettings Function(AppSettings) mutator,
    required String key,
    required String? value,
  }) async {
    _value = mutator(_value);
    notifyListeners();
    if (value == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, value);
    }
  }

  Future<void> _persist(String key, Object? value) async {
    try {
      if (value == null) {
        await _prefs.remove(key);
        return;
      }
      switch (value) {
        case bool b:
          await _prefs.setBool(key, b);
        case int i:
          await _prefs.setInt(key, i);
        case String s:
          await _prefs.setString(key, s);
        default:
          if (kDebugMode) {
            // ignore: avoid_print
            print('SettingsController: unsupported value type for $key');
          }
      }
    } on Exception catch (_) {
      // Persistence failures don't block the UI — the in-memory value still
      // wins. Logged via print in debug; future Phase 1+ will route through the
      // logging package once it is wired into a UI surface.
      if (kDebugMode) {
        // ignore: avoid_print
        print('SettingsController: failed to persist $key');
      }
    }
  }

  Future<AppSettings> _readAll() async {
    final p = _prefs;
    return AppSettings(
      themeMode: _themeModeFromString(
        await p.getString(SettingsKeys.themeMode),
      ),
      localeCode: AppLocaleCode.fromPersistedName(
        await p.getString(SettingsKeys.localeCode),
      ),
      reopenLastWorkspace:
          await p.getBool(SettingsKeys.reopenLastWorkspace) ?? false,
      checkUpdatesOnLaunch:
          await p.getBool(SettingsKeys.checkUpdatesOnLaunch) ?? true,
      preferMetric: await p.getBool(SettingsKeys.preferMetric) ?? true,
      xplaneInstallPath: await p.getString(SettingsKeys.xplaneInstallPath),
      xplaneUdpPort: await p.getInt(SettingsKeys.xplaneUdpPort) ?? 49000,
      xplaneBridgePort: await p.getInt(SettingsKeys.xplaneBridgePort) ?? 49001,
      useOurAirports: await p.getBool(SettingsKeys.useOurAirports) ?? true,
      useFaaCifp: await p.getBool(SettingsKeys.useFaaCifp) ?? true,
      useXplaneNative: await p.getBool(SettingsKeys.useXplaneNative) ?? true,
      navigraphUser: await p.getString(SettingsKeys.navigraphUser),
      navigraphAirac: await p.getString(SettingsKeys.navigraphAirac),
      simbriefUsername: await p.getString(SettingsKeys.simbriefUsername),
      aiProvider: AiProvider.fromPersistedName(
        await p.getString(SettingsKeys.aiProvider),
      ),
      aiEndpoint: await p.getString(SettingsKeys.aiEndpoint),
      aiModel: await p.getString(SettingsKeys.aiModel),
      aiConfirmWrites: await p.getBool(SettingsKeys.aiConfirmWrites) ?? true,
      aiAutoRead: await p.getBool(SettingsKeys.aiAutoRead) ?? true,
      remoteEnabled: await p.getBool(SettingsKeys.remoteEnabled) ?? false,
      remotePort: await p.getInt(SettingsKeys.remotePort) ?? 48080,
      remoteToken: await p.getString(SettingsKeys.remoteToken) ?? '',
      remoteMdns: await p.getBool(SettingsKeys.remoteMdns) ?? true,
      mapTileProvider: MapTileProvider.fromPersistedName(
          await p.getString(SettingsKeys.mapTileProvider)),
      mapTheme: MapTheme.fromPersistedName(
          await p.getString(SettingsKeys.mapTheme)),
      selectedMapApiKeyId: await p.getString(SettingsKeys.selectedMapApiKeyId),
      apiKeys: ApiKeyEntry.decodeList(await p.getString(SettingsKeys.apiKeys)),
      simulators: SimulatorInstall.decodeList(
          await p.getString(SettingsKeys.simulators)),
      navdataSources: NavdataSource.decodeList(
          await p.getString(SettingsKeys.navdataSources)),
    );
  }

  Future<void> _clearAll() async {
    final keys = [
      SettingsKeys.themeMode,
      SettingsKeys.localeCode,
      SettingsKeys.reopenLastWorkspace,
      SettingsKeys.checkUpdatesOnLaunch,
      SettingsKeys.preferMetric,
      SettingsKeys.xplaneInstallPath,
      SettingsKeys.xplaneUdpPort,
      SettingsKeys.xplaneBridgePort,
      SettingsKeys.useOurAirports,
      SettingsKeys.useFaaCifp,
      SettingsKeys.useXplaneNative,
      SettingsKeys.navigraphUser,
      SettingsKeys.navigraphAirac,
      SettingsKeys.simbriefUsername,
      SettingsKeys.aiProvider,
      SettingsKeys.aiEndpoint,
      SettingsKeys.aiModel,
      SettingsKeys.aiConfirmWrites,
      SettingsKeys.aiAutoRead,
      SettingsKeys.remoteEnabled,
      SettingsKeys.remotePort,
      SettingsKeys.remoteToken,
      SettingsKeys.remoteMdns,
      SettingsKeys.mapTileProvider,
      SettingsKeys.mapTheme,
      SettingsKeys.selectedMapApiKeyId,
      SettingsKeys.apiKeys,
    ];
    for (final key in keys) {
      try {
        await _prefs.remove(key);
      } on Exception catch (_) {
        // Best-effort: keep clearing the remaining keys.
      }
    }
  }

  static ThemeMode _themeModeFromString(String? name) {
    switch (name) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}

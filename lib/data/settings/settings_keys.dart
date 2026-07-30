/// String keys for every persisted setting.
///
/// Centralised so the controller is the single source of truth for the
/// SharedPreferences namespace. Names mirror the field names on [AppSettings]
/// but live in their own constant so accidental typos surface as compile-time
/// renames rather than silent misses.
class SettingsKeys {
  SettingsKeys._();

  // General / appearance
  static const themeMode = 'general.themeMode';
  static const localeCode = 'general.localeCode';
  static const reopenLastWorkspace = 'general.reopenLastWorkspace';
  static const checkUpdatesOnLaunch = 'general.checkUpdatesOnLaunch';
  static const preferMetric = 'general.preferMetric';

  // X-Plane 12
  static const xplaneInstallPath = 'xplane.installPath';
  static const xplaneUdpPort = 'xplane.udpPort';
  static const xplaneBridgePort = 'xplane.bridgePort';

  // Navigation data
  static const useOurAirports = 'navdata.useOurAirports';
  static const useFaaCifp = 'navdata.useFaaCifp';
  static const useXplaneNative = 'navdata.useXplaneNative';
  static const navigraphUser = 'navdata.navigraphUser';
  static const navigraphAirac = 'navdata.navigraphAirac';
  static const simbriefUsername = 'navdata.simbriefUsername';

  // AI Copilot
  static const aiProvider = 'ai.provider';
  static const aiApiKey = 'ai.apiKey';
  static const aiEndpoint = 'ai.endpoint';
  static const aiModel = 'ai.model';
  static const aiConfirmWrites = 'ai.confirmWrites';
  static const aiAutoRead = 'ai.autoRead';

  // Remote access
  static const remoteEnabled = 'remote.enabled';
  static const remotePort = 'remote.port';
  static const remoteToken = 'remote.token';
  static const remoteMdns = 'remote.mdns';
}

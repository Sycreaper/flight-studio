import 'dart:io' show Platform;

import '../settings/app_settings.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_enums.dart';
import '../settings/simulator_install.dart';
import 'navdata_provider.dart';
import 'navdata_service.dart';

/// Whether an automatic navdata scan should run for [mode], given the last
/// successful scan time.
bool isNavdataScanDue(SplashScanMode mode, DateTime? lastScanAt) {
  switch (mode) {
    case SplashScanMode.never:
      return false;
    case SplashScanMode.always:
      return true;
    case SplashScanMode.after14Days:
    case SplashScanMode.after28Days:
      if (lastScanAt == null) return true;
      final threshold = mode == SplashScanMode.after14Days
          ? const Duration(days: 14)
          : const Duration(days: 28);
      return DateTime.now().toUtc().difference(lastScanAt.toUtc()) > threshold;
  }
}

/// Resolves which simulator install the user's selected (radio) navdata
/// source points to. Falls back to the first install with a registered
/// provider when no explicit selection exists (or it points nowhere).
SimulatorInstall? resolveImportTarget(AppSettings settings) {
  final activeId = settings.activeNavdataSourceId;
  if (activeId != null) {
    for (final source in settings.navdataSources) {
      if (source.id != activeId) continue;
      for (final sim in settings.simulators) {
        if (sim.id == source.simulatorId) return sim;
      }
    }
  }
  for (final sim in settings.simulators) {
    if (NavdataProviderRegistry.instance.forInstall(sim) != null) return sim;
  }
  return null;
}

/// Full "check all navigation data" pass honouring the active source
/// selection. Returns `false` when there is no importable target.
Future<bool> importSelectedNavdata(AppSettings settings) async {
  final target = resolveImportTarget(settings);
  if (target == null) return false;
  await NavdataService.instance.importFromSimulators([target]);
  return true;
}

/// Headless startup navdata scan — used when the splash screen is DISABLED
/// but a scan is due. Progress is visible through the usual channels (spinning
/// gear button + gear menu progress entries). Fire-and-forget.
Future<void> runStartupNavdataScanIfNeeded(SettingsController settings) async {
  // path_provider never completes under `flutter test` (FakeAsync).
  if (Platform.environment.containsKey('FLUTTER_TEST')) return;
  final s = settings.value;
  if (!isNavdataScanDue(s.splashScanMode, s.lastNavdataScanAt)) return;
  await importSelectedNavdata(s);
}

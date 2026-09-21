// Startup scan decision tests: splash-scan settings persist correctly and
// the "due" thresholds behave (always / never / 14-day / 28-day windows).

import 'package:flight_studio/data/navdata/built_in_providers.dart';
import 'package:flight_studio/data/navdata/startup_scan.dart';
import 'package:flight_studio/data/settings/settings_controller.dart';
import 'package:flight_studio/data/settings/settings_enums.dart';
import 'package:flight_studio/data/settings/simulator_install.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('isNavdataScanDue', () {
    final now = DateTime.now().toUtc();

    test('always → always due; never → never due', () {
      expect(isNavdataScanDue(SplashScanMode.always, now), isTrue);
      expect(isNavdataScanDue(SplashScanMode.never, null), isFalse);
    });

    test('threshold modes are due when no scan has ever run', () {
      expect(isNavdataScanDue(SplashScanMode.after14Days, null), isTrue);
      expect(isNavdataScanDue(SplashScanMode.after28Days, null), isTrue);
    });

    test('14-day window', () {
      final fresh = now.subtract(const Duration(days: 3));
      final stale = now.subtract(const Duration(days: 15));
      expect(isNavdataScanDue(SplashScanMode.after14Days, fresh), isFalse);
      expect(isNavdataScanDue(SplashScanMode.after14Days, stale), isTrue);
    });

    test(
      '28-day window: a 20-day-old scan is fresh for 28d, stale for 14d',
      () {
        final scan = now.subtract(const Duration(days: 20));
        expect(isNavdataScanDue(SplashScanMode.after28Days, scan), isFalse);
        expect(isNavdataScanDue(SplashScanMode.after14Days, scan), isTrue);
      },
    );
  });

  group('splash settings round-trip', () {
    test('splashEnabled + splashScanMode persist and reload', () async {
      final controller = SettingsController();
      await controller.load();
      expect(controller.value.splashEnabled, isTrue);
      expect(controller.value.splashScanMode, SplashScanMode.always);

      await controller.setSplashEnabled(false);
      await controller.setSplashScanMode(SplashScanMode.after28Days);

      final reloaded = SettingsController();
      await reloaded.load();
      expect(reloaded.value.splashEnabled, isFalse);
      expect(reloaded.value.splashScanMode, SplashScanMode.after28Days);
    });

    test('resetToDefaults restores splash settings', () async {
      final controller = SettingsController();
      await controller.load();
      await controller.setSplashEnabled(false);
      await controller.setSplashScanMode(SplashScanMode.never);
      await controller.resetToDefaults();
      expect(controller.value.splashEnabled, isTrue);
      expect(controller.value.splashScanMode, SplashScanMode.always);
    });
  });

  group('active navdata source selection', () {
    setUp(registerBuiltInNavdataProviders);

    test('persists across reload and clears to automatic fallback', () async {
      final controller = SettingsController();
      await controller.load();
      expect(controller.value.activeNavdataSourceId, isNull);

      await controller.setActiveNavdataSource('src_abc');
      final reloaded = SettingsController();
      await reloaded.load();
      expect(reloaded.value.activeNavdataSourceId, 'src_abc');

      await reloaded.setActiveNavdataSource(null);
      final again = SettingsController();
      await again.load();
      expect(again.value.activeNavdataSourceId, isNull);
    });

    test('resolveImportTarget: selection wins over fallback order', () async {
      final controller = SettingsController();
      await controller.load();
      final simA = await _addSim(controller, 'sim-a');
      final simB = await _addSim(controller, 'sim-b');
      await controller.setActiveNavdataSource(
        await controller.addNavdataSource(simB.id, NavdataDataType.defaultData),
      );

      // Selection points at simB even though simA was registered first.
      final target = resolveImportTarget(controller.value);
      expect(target, isNotNull);
      expect(target!.id, simB.id);

      // Selection pointing at a removed sim → falls back to first
      // provider-compatible install (simA).
      await controller.removeNavdataSource(
        controller.value.activeNavdataSourceId!,
      );
      await controller.setActiveNavdataSource('ghost');
      expect(resolveImportTarget(controller.value)!.id, simA.id);
    });
  });
}

Future<SimulatorInstall> _addSim(
  SettingsController controller,
  String name,
) async {
  await controller.addSimulator(SimulatorType.xplane12, r'C:\Sims', name: name);
  return controller.value.simulators.last;
}

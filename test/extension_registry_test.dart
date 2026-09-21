// Unit tests for the plugin-ready extension-point registries: the generic
// ExtensionRegistry, the tab registry/controller integration, and the
// built-in registrations for simulator connectors, navdata providers and
// exporters.

import 'package:flight_studio/core/flightplan/exporters/flight_plan_exporter.dart';
import 'package:flight_studio/data/navdata/built_in_providers.dart';
import 'package:flight_studio/data/navdata/navdata_provider.dart';
import 'package:flight_studio/data/settings/simulator_install.dart';
import 'package:flight_studio/plugins/extension_registry.dart';
import 'package:flight_studio/sim/built_in_connectors.dart';
import 'package:flight_studio/sim/simulator_connector.dart';
import 'package:flight_studio/sim/xplane/xplane_connector.dart';
import 'package:flight_studio/ui/shell/tabs/app_tab_controller.dart';
import 'package:flight_studio/ui/shell/tabs/tab_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts listener notifications on a registry.
class NotificationCounter {
  NotificationCounter(this.listenable) {
    listenable.addListener(_bump);
  }

  final Listenable listenable;
  int count = 0;

  void _bump() => count++;
}

class _FakeExporter extends FlightPlanExporter {
  _FakeExporter(this.formatId, this.fileExtensions);

  @override
  final String formatId;
  @override
  final List<String> fileExtensions;

  @override
  String get displayName => formatId;

  @override
  Future<List<int>> export(ExportableFlightPlan plan) async => [];
}

TabDescriptor _descriptor(
  String id, {
  bool singleton = false,
  bool showInNewTabMenu = true,
}) => TabDescriptor(
  id: id,
  title: (l10n) => id,
  icon: Icons.tab_rounded,
  createContent: (_) => const SizedBox.shrink(),
  singleton: singleton,
  showInNewTabMenu: showInNewTabMenu,
);

void main() {
  group('ExtensionRegistry', () {
    test('registers, looks up, replaces and unregisters by id', () {
      final reg = ExtensionRegistry<String>(idOf: (s) => s.toUpperCase());
      final notify = NotificationCounter(reg);

      reg.register('alpha');
      expect(reg.byId('ALPHA'), 'alpha');
      expect(reg.all, ['alpha']);
      expect(notify.count, 1);

      // Last-writer-wins on the same id.
      reg.register('alpha2', id: 'ALPHA');
      expect(reg.all, ['alpha2']);

      // Explicit id override.
      reg.register('beta', id: 'custom');
      expect(reg.byId('custom'), 'beta');

      expect(reg.unregister('custom'), isTrue);
      expect(reg.unregister('custom'), isFalse);
      expect(reg.byId('custom'), isNull);
      // 3 successful registers + 1 successful unregister.
      expect(notify.count, 4);
    });

    test('first() scans registration order', () {
      final reg = ExtensionRegistry<int>(idOf: (i) => 'k$i');
      reg.register(1);
      reg.register(22);
      reg.register(333);
      expect(reg.first((v) => v > 10), 22);
      expect(reg.first((v) => v > 999), isNull);
    });
  });

  group('TabRegistry + AppTabController', () {
    test('descriptor lookups drive singleton behaviour', () {
      final registry = TabRegistry()
        ..register(_descriptor(TabIds.map))
        ..register(_descriptor('singleton-kind', singleton: true));
      final controller = AppTabController(registry: registry);

      // Seeded map tab exists; a second add() creates a duplicate (non-
      // singleton kind).
      controller.add(TabIds.map);
      expect(controller.tabsOfType(TabIds.map).length, 2);

      // Singleton kind: second add focuses the existing tab.
      controller.add('singleton-kind');
      controller.add('singleton-kind');
      expect(controller.tabsOfType('singleton-kind').length, 1);
      expect(controller.selectedOrNull?.typeId, 'singleton-kind');
    });

    test('openOrCreate focuses the singleton instead of duplicating', () {
      final registry = TabRegistry()
        ..register(
          _descriptor(
            TabIds.settings,
            singleton: true,
            showInNewTabMenu: false,
          ),
        );
      final controller = AppTabController(registry: registry);
      controller.openOrCreate(TabIds.settings);
      controller.openOrCreate(TabIds.settings);
      expect(controller.tabsOfType(TabIds.settings).length, 1);
    });

    test('bare controller (no registry) still opens tabs', () {
      final controller = AppTabController();
      controller.add('anything');
      expect(controller.tabsOfType('anything').length, 1);
    });
  });

  group('built-in registrations', () {
    test('registerBuiltInSimConnectors enables X-Plane 12 only', () {
      registerBuiltInSimConnectors();
      final reg = SimConnectorRegistry.instance;

      expect(reg.isSupported(SimulatorType.xplane12), isTrue);
      expect(reg.isSupported(SimulatorType.msfs2020), isFalse);
      expect(reg.isSupported(SimulatorType.prepar3dV6), isFalse);

      final connector = reg.create(SimulatorType.xplane12);
      expect(connector, isA<XPlaneConnector>());
      expect(reg.create(SimulatorType.msfs2024), isNull);
    });

    test('registerBuiltInNavdataProviders resolves the X-Plane provider', () {
      registerBuiltInNavdataProviders();
      final reg = NavdataProviderRegistry.instance;

      final xp = SimulatorInstall(
        id: 's1',
        type: SimulatorType.xplane12,
        path: r'C:\X-Plane 12',
      );
      final msfs = SimulatorInstall(
        id: 's2',
        type: SimulatorType.msfs2020,
        path: r'C:\MSFS',
      );

      expect(reg.forInstall(xp)?.id, 'xplane12');
      expect(reg.forInstall(msfs), isNull);
    });
  });

  group('ExporterRegistry', () {
    test('lookup by format id and by file extension', () {
      final reg = ExporterRegistry();
      reg.register(_FakeExporter('fms11', ['fms']));
      reg.register(_FakeExporter('pln', ['pln']));

      expect(reg.byId('fms11')?.displayName, 'fms11');
      expect(reg.forExtension('PLN')?.formatId, 'pln');
      expect(reg.forExtension('gpx'), isNull);
    });
  });
}

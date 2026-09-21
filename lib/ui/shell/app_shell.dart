import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/geo/geo_math.dart';
import '../../../core/navdata/navdata_types.dart';
import '../../../data/background_tasks.dart';
import '../../../data/navdata/navdata_service.dart';
import '../../../data/settings/settings_controller.dart';
import '../../../data/system/system_stats_service.dart';
import '../../../l10n/app_localizations.dart';
import '../map/map_canvas.dart';
import '../map/nav_markers.dart';
import '../settings/settings_page.dart';
import '../theme/app_colors.dart';
import '../workspace/defaults.dart';
import '../workspace/workspace_controller.dart';
import '../workspace/workspace_view.dart';
import 'form_toolbar.dart';
import 'map_toolbar.dart';
import 'status_bar.dart';
import 'tabs/app_tab.dart';
import 'tabs/app_tab_bar.dart';
import 'tabs/app_tab_controller.dart';
import 'tabs/flight_plan_form_tab.dart';
import 'tabs/map_tab_view.dart';
import 'tabs/settings_tab_view.dart';
import 'tabs/tab_registry.dart';

/// The main application window, laid out like JetBrains IDEA.
///
/// The workspace (tool docks + drawers + sizes) is owned here and **shared**
/// across all tabs; switching tabs only swaps the centre card (map / form /
/// settings), preserving drawer layout and drawer content state. Each tab's
/// centre is kept alive in an [IndexedStack] so per-tab state survives.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.settings,
    this.initialTab,
    this.initialSettingsSection,
  });

  final SettingsController settings;

  /// When non-null (a [TabIds] constant, or a plugin tab id once plugins
  /// exist), the shell opens with this tab kind instead of the default map
  /// tab. Used by the gear menu to push a settings-only workspace from the
  /// welcome screen.
  final String? initialTab;

  /// When [initialTab] is [TabIds.settings], optionally land on this section.
  final SettingsSection? initialSettingsSection;

  @override
  State<AppShell> createState() => AppShellState();
}

/// Public so external callers (the gear-menu dispatcher) can ask the live
/// workspace to open / switch to the settings tab.
class AppShellState extends State<AppShell> {
  late final AppTabController _tabController;
  late final WorkspaceController _workspace;

  /// Registry of tab kinds — built-ins registered in [initState]; a future
  /// plugin manager would register additional kinds here the same way.
  final TabRegistry _tabRegistry = TabRegistry();

  final GlobalKey<SettingsTabViewState> _settingsTabKey = GlobalKey();
  final Set<NavPointCategory> _navVisible = NavPointCategory.values.toSet();

  /// Live map zoom published by [MapCanvas]; drives legend-bar visibility.
  final ValueNotifier<double> _mapZoom = ValueNotifier<double>(3);

  /// Fly-to target published by the search drawer; [MapCanvas] consumes it.
  final ValueNotifier<LatLng?> _flyToTarget = ValueNotifier<LatLng?>(null);

  /// Map centre coordinates published by [MapCanvas]; shown in the status bar.
  final ValueNotifier<LatLng?> _mapCenter = ValueNotifier<LatLng?>(null);

  /// 1-second tick driving the status-bar clock.
  final ValueNotifier<int> _tick = ValueNotifier<int>(0);
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _registerTabs();
    _tabController = AppTabController(registry: _tabRegistry);
    if (widget.initialTab != null && widget.initialTab != TabIds.map) {
      final seeded = _tabController.tabs.first;
      _tabController.close(seeded.id);
      if (widget.initialTab == TabIds.settings) {
        _tabController.openOrCreate(TabIds.settings);
      } else {
        _tabController.add(widget.initialTab!);
      }
    }
    _workspace = WorkspaceController();
    // Default panels are registered on first build (see [_registerDefaults])
    // so we have a BuildContext for localised titles.

    // Live status-bar data — skipped inside `flutter test` (FLUTTER_TEST env
    // var): the 1 s clock tick would keep pumpAndSettle from settling.
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _tick.value = _tick.value + 1;
      });
      SystemStatsService.instance.start();
    }
  }

  /// Registers the built-in tab kinds. This is the exact channel a future
  /// plugin manager uses — the shell never special-cases a tab kind, it only
  /// consults the registry.
  void _registerTabs() {
    _tabRegistry..register(
      TabDescriptor(
        id: TabIds.map,
        title: (l10n) => l10n.tabMap,
        icon: Icons.map_outlined,
        showsNavLegend: true,
        createContent: (tab) =>
            MapTabView(
              key: ValueKey('map_${tab.id}'),
              navVisible: _navVisible,
              zoomNotifier: _mapZoom,
              flyToTarget: _flyToTarget,
            ),
        createToolbar: (context) =>
            MapToolbar(
              onNew: _newFormTab,
              onOpen: () {},
            ),
      ),
    )..register(
      TabDescriptor(
        id: TabIds.flightPlan,
        title: (l10n) => l10n.tabFlightPlan,
        icon: Icons.description_outlined,
        createContent: (tab) =>
            FlightPlanFormTab(key: ValueKey('plan_${tab.id}')),
        createToolbar: (context) =>
            FormToolbar(
              onCalculate: () {},
              onReset: () {},
            ),
      ),
    )..register(
      TabDescriptor(
        id: TabIds.settings,
        title: (l10n) => l10n.tabSettings,
        icon: Icons.settings_rounded,
        singleton: true,
        showInNewTabMenu: false,
        // Settings tab has no toolbar — the page fills the workspace.
        createContent: (tab) =>
            SettingsTabView(
              key: _settingsTabKey,
              controller: widget.settings,
              initialSection:
              widget.initialSettingsSection ?? SettingsSection.general,
            ),
      ),
    );
  }

  bool _defaultsRegistered = false;

  void _registerDefaults(BuildContext context) {
    if (_defaultsRegistered) return;
    _defaultsRegistered = true;
    for (final p in buildDefaultPanels(
      onCreateFlightPlan: () => _tabController.add(TabIds.flightPlan),
      onFlyTo: _flyTo,
    )) {
      _workspace.register(p);
    }
  }

  /// Ensures a Map tab exists and is selected, then flies the camera to
  /// [target]. Invoked from the search drawer's result tiles.
  void _flyTo(LatLng target) {
    final mapTabs = _tabController.tabsOfType(TabIds.map);
    if (mapTabs.isNotEmpty) {
      _tabController.select(mapTabs.first.id);
    } else {
      _tabController.add(TabIds.map);
    }
    _flyToTarget.value = target;
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _tabController.dispose();
    _workspace.dispose();
    _mapZoom.dispose();
    _flyToTarget.dispose();
    _mapCenter.dispose();
    _tick.dispose();
    super.dispose();
  }

  void _newFormTab() => _tabController.add(TabIds.flightPlan);

  void _goHome() {
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  /// Opens the settings tab (singleton). If a settings tab already exists it is
  /// selected and [goToSection] is called on its live state; if not, a new one
  /// is created with [section] as the initial landing spot.
  void openSettingsTab({SettingsSection? section}) {
    _tabController.openOrCreate(TabIds.settings);
    if (section != null) {
      // Use a post-frame callback so the widget is mounted before we call
      // its state method (especially important when the tab was just created
      // and hasn't built yet).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _settingsTabKey.currentState?.goToSection(section);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _registerDefaults(context);
    return Scaffold(
      backgroundColor: Theme.of(context).extension<AppColors>()!.chrome,
      // stretch guarantees the tab bar, toolbars and status bar all span the
      // full window width — no intrinsic-width centering, no side blanks.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTabBar(controller: _tabController, onHome: _goHome),
          ListenableBuilder(
            listenable: _tabController,
            builder: (context, _) => _buildToolbar(),
          ),
          // Nav legend bar — only shown on tab kinds flagged [TabDescriptor.
          // showsNavLegend], and only when zoomed in far enough for a
          // viewport query to cover its visible area (matching the
          // marker-layer zoom gate in MapCanvas).
          ListenableBuilder(
            listenable: _tabController,
            builder: (context, _) {
              final tab = _tabController.selectedOrNull;
              final showsLegend = tab != null &&
                  (_tabRegistry
                      .descriptorOf(tab.typeId)
                      ?.showsNavLegend ??
                      false);
              if (!showsLegend) {
                return const SizedBox.shrink();
              }
              return ValueListenableBuilder<double>(
                valueListenable: _mapZoom,
                builder: (context, zoom, _) {
                  return NavLegendBar(
                    visible: _navVisible,
                    enabled: zoom >= MapCanvas.minMarkerZoom,
                    onToggle: (cat) =>
                        setState(() {
                          if (_navVisible.contains(cat)) {
                            _navVisible.remove(cat);
                          } else {
                            _navVisible.add(cat);
                          }
                        }),
                  );
                },
              );
            },
          ),
          Expanded(child: _buildBody()),
          // Status bar rebuilds on: 1 s clock tick, stats poll (2 s),
          // background-task changes, navdata import completion, map centre
          // moves.
          ListenableBuilder(
            listenable: Listenable.merge([
              _tick,
              SystemStatsService.instance,
              BackgroundTaskManager.instance,
              NavdataService.instance,
              _mapCenter,
            ]),
            builder: (context, _) =>
                SizedBox(
                  width: double.infinity,
                  child: StatusBar(
                    isConnected: false,
                    dataCycle: _dataCycleText(),
                    coordinate: _coordinateText(),
                    utcTime: _utcNow(),
                    cpuUsage: SystemStatsService.instance.stats.cpuPercent,
                    gpuUsage: SystemStatsService.instance.stats.gpuPercent,
                    memoryUsage: SystemStatsService.instance.stats
                        .memoryPercent,
                    tasks: BackgroundTaskManager.instance
                        .tasks
                        .map((t) =>
                        StatusProgressTask(
                          label: t.label,
                          progress: t.progress,
                          isComplete: t.isComplete,
                        ))
                        .toList(),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  /// One-line navdata summary for the status bar (empty until an import ran).
  String _dataCycleText() {
    final counts = NavdataService.instance.rowCounts;
    if (counts.isEmpty || counts.values.every((c) => c == 0)) return '';
    String k(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v';
    return 'Apt ${k(counts['airports'] ?? 0)}'
        ' · Nav ${k(counts['navaids'] ?? 0)}'
        ' · Fix ${k(counts['fixes'] ?? 0)}'
        ' · Awy ${k(counts['airways'] ?? 0)}';
  }

  /// DMS-formatted map centre coordinates for the status bar.
  String _coordinateText() {
    final c = _mapCenter.value;
    if (c == null) return "N00°00'00\" E000°00'00\"";
    return '${formatLatDMS(c.latitude)} ${formatLonDMS(c.longitude)}';
  }

  String _utcNow() {
    final now = DateTime.now().toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(now.hour)}:${two(now.minute)}:${two(now.second)} UTC';
  }

  Widget _buildToolbar() {
    final tab = _tabController.selectedOrNull;
    if (tab == null) {
      return const SizedBox(height: 0, width: 0);
    }
    final toolbar = _tabRegistry
        .descriptorOf(tab.typeId)
        ?.createToolbar;
    return toolbar?.call(context) ?? const SizedBox(height: 0, width: 0);
  }

  Widget _buildBody() {
    return ListenableBuilder(
      listenable: Listenable.merge([_tabController, _workspace]),
      builder: (context, _) {
        if (_tabController.isEmpty) {
          return const _EmptyTabsState();
        }
        return WorkspaceView(
          controller: _workspace,
          center: _buildCenter(),
        );
      },
    );
  }

  /// All open tabs' centres kept alive in a stack; only the selected one shows.
  Widget _buildCenter() {
    final tabs = _tabController.tabs;
    final selectedId = _tabController.selectedOrNull?.id;
    var index = tabs.indexWhere((t) => t.id == selectedId);
    if (index < 0) index = 0;
    return IndexedStack(
      index: index,
      children: [for (final t in tabs) _centerForTab(t)],
    );
  }

  /// Content for one open tab, resolved through the registry. Unknown ids
  /// (e.g. a plugin tab whose plugin failed to load) degrade to a placeholder.
  Widget _centerForTab(AppTab tab) {
    final descriptor = _tabRegistry.descriptorOf(tab.typeId);
    if (descriptor == null) {
      return _unknownTabContent();
    }
    return descriptor.createContent(tab);
  }

  Widget _unknownTabContent() {
    return Center(
      child: Icon(
        Icons.extension_rounded,
        size: 40,
        color: Theme.of(context).extension<AppColors>()!.textDisabled,
      ),
    );
  }
}

/// Shown when the user has closed every tab.
class _EmptyTabsState extends StatelessWidget {
  const _EmptyTabsState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tab_rounded, size: 48, color: colors.textDisabled),
          const SizedBox(height: 14),
          Text(
            l10n.noOpenTabs,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.clickPlusToOpen,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: colors.textDisabled),
          ),
        ],
      ),
    );
  }
}


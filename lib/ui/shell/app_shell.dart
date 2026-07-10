import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'form_toolbar.dart';
import 'map_toolbar.dart';
import 'status_bar.dart';
import 'tabs/app_tab.dart';
import 'tabs/app_tab_bar.dart';
import 'tabs/app_tab_controller.dart';
import 'tabs/flight_plan_form_tab.dart';
import 'tabs/map_tab_view.dart';

/// The main application window, laid out like JetBrains IDEA:
///
/// ```
/// ┌──────────────────────────────────────────────┐
/// │ AppTabBar (tabs + "+")                        │
/// ├──────────────────────────────────────────────┤
/// │ Per-tab toolbar (changes with active tab)     │
/// ├──────────────────────────────────────────────┤
/// │  Active tab content (full width)              │
/// │   Map tab: tree + map + profile + inspector   │
/// │   Plan tab: bordered form                     │
/// ├──────────────────────────────────────────────┤
/// │ StatusBar                                     │
/// └──────────────────────────────────────────────┘
/// ```
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final AppTabController _tabController = AppTabController();

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).extension<AppColors>()!.chrome,
      body: Column(
        children: [
          AppTabBar(controller: _tabController),
          ListenableBuilder(
            listenable: _tabController,
            builder: (context, _) => _buildToolbar(),
          ),
          Expanded(
            child: _buildTabContent(),
          ),
          StatusBar(
            isConnected: false,
            dataCycle: 'No navdata loaded',
            coordinate: "N00°00'00\" E000°00'00\"",
            utcTime: _utcNow(),
            cpuUsage: '0%',
            memoryUsage: '0 MB',
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    final tab = _tabController.selectedOrNull;
    if (tab == null) {
      return const SizedBox(height: 0, width: 0);
    }
    switch (tab.type) {
      case TabType.map:
        return MapToolbar(
          onNew: () => _tabController.add(TabType.flightPlan),
          onOpen: () {},
        );
      case TabType.flightPlan:
        return FormToolbar(
          onCalculate: () {},
          onReset: () {},
        );
    }
  }

  Widget _buildTabContent() {
    return ListenableBuilder(
      listenable: _tabController,
      builder: (context, _) {
        if (_tabController.isEmpty) {
          return const _EmptyTabsState();
        }
        final tab = _tabController.selectedOrNull!;
        switch (tab.type) {
          case TabType.map:
            return MapTabView(
              onCreateFlightPlan: () =>
                  _tabController.add(TabType.flightPlan),
            );
          case TabType.flightPlan:
            return FlightPlanFormTab(
              onCreateFlightPlan: () =>
                  _tabController.add(TabType.flightPlan),
            );
        }
      },
    );
  }

  String _utcNow() {
    final now = DateTime.now().toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(now.hour)}:${two(now.minute)}:${two(now.second)} UTC';
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

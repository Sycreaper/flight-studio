import 'package:flutter/material.dart';

import '../../../data/settings/settings_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../settings_page.dart';
import '../../theme/app_colors.dart';
import 'api_keys_section.dart';
import 'navdata_section.dart';
import 'simulator_section.dart';

/// The Data settings category: API keys, simulators and navdata sources
/// behind one native tab bar (the same style the airport inspector uses —
/// scrollable, label-sized accent indicator, transparent divider).
///
/// [initialTab] selects the tab shown when the section opens (landing
/// precision for the gear menu / map shortcuts); it only applies on first
/// build — afterwards the user's own tab choice wins.
class DataSection extends StatefulWidget {
  const DataSection({
    super.key,
    required this.controller,
    this.initialTab,
  });

  final SettingsController controller;
  final SettingsDataTab? initialTab;

  @override
  State<DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends State<DataSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabCount = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabCount,
      vsync: this,
      initialIndex: switch (widget.initialTab) {
        SettingsDataTab.simulators => 1,
        SettingsDataTab.navdata => 2,
        _ => 0,
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          indicatorColor: colors.accent,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: colors.accent,
          unselectedLabelColor: colors.textSecondary,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          tabs: [
            Tab(text: l10n.settingsCategoryApiKeys),
            Tab(text: l10n.settingsCategorySimulator),
            Tab(text: l10n.settingsCategoryNavdata),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              ApiKeysSection(controller: widget.controller),
              SimulatorSection(controller: widget.controller),
              NavDataSection(controller: widget.controller),
            ],
          ),
        ),
      ],
    );
  }
}

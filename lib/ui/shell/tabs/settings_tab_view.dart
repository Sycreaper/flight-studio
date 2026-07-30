import 'package:flutter/material.dart';

import '../../../data/settings/settings_controller.dart';
import '../../settings/settings_page.dart';
import '../../theme/app_colors.dart';

/// Renders the [SettingsPage] as a workspace centre card.
///
/// Unlike map / flight-plan tabs which get their own toolbar, the settings tab
/// has no toolbar — it fills the workspace centre directly, matching VS Code's
/// settings tab layout.
class SettingsTabView extends StatefulWidget {
  const SettingsTabView({
    super.key,
    required this.controller,
    this.initialSection = SettingsSection.general,
  });

  final SettingsController controller;

  /// Which section to show when the tab first opens. Only read once on
  /// [initState]; subsequent section changes come from the user's own nav.
  final SettingsSection initialSection;

  @override
  State<SettingsTabView> createState() => SettingsTabViewState();
}

/// Public state so an external caller (e.g. the gear menu's "About" action)
/// can ask the live settings tab to jump to a specific section without a
/// rebuild via key.
class SettingsTabViewState extends State<SettingsTabView> {
  late SettingsSection _section;

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
  }

  /// Jump to a specific section. Called when the gear menu's "About" entry is
  /// picked and the settings tab is already open.
  void goToSection(SettingsSection section) {
    setState(() => _section = section);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SettingsPage(
        controller: widget.controller,
        section: _section,
        onChangeSection: (s) => setState(() => _section = s),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../data/settings/settings_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../adaptive/breakpoints.dart';
import '../theme/app_colors.dart';
import 'sections/about_section.dart';
import 'sections/ai_copilot_section.dart';
import 'sections/api_keys_section.dart';
import 'sections/general_section.dart';
import 'sections/navdata_section.dart';
import 'sections/remote_access_section.dart';
import 'sections/simulator_section.dart';

/// The categories shown in the settings nav rail. Public so the gear-menu can
/// request a landing section without re-implementing the list.
enum SettingsSection { general, apiKeys, simulator, navdata, ai, remote, about }

/// Per-section icon, shared by the nav rail and the narrow-screen detail page.
IconData settingsSectionIcon(SettingsSection section) =>
    switch (section) {
      SettingsSection.general => Icons.tune_rounded,
      SettingsSection.apiKeys => Icons.vpn_key_rounded,
      SettingsSection.simulator => Icons.flight_takeoff_rounded,
      SettingsSection.navdata => Icons.map_rounded,
      SettingsSection.ai => Icons.auto_awesome_rounded,
      SettingsSection.remote => Icons.devices_rounded,
      SettingsSection.about => Icons.info_outline_rounded,
    };

/// Per-section localized title, shared by the nav rail and the narrow-screen
/// detail page header.
String settingsSectionTitle(AppLocalizations l10n, SettingsSection section) =>
    switch (section) {
      SettingsSection.general => l10n.settingsCategoryGeneral,
      SettingsSection.apiKeys => l10n.settingsCategoryApiKeys,
      SettingsSection.simulator => l10n.settingsCategorySimulator,
      SettingsSection.navdata => l10n.settingsCategoryNavdata,
      SettingsSection.ai => l10n.settingsCategoryAi,
      SettingsSection.remote => l10n.settingsCategoryRemote,
      SettingsSection.about => l10n.settingsCategoryAbout,
    };

/// Per-section localized one-line description (nav rail subtitle).
String settingsSectionDesc(AppLocalizations l10n, SettingsSection section) =>
    switch (section) {
      SettingsSection.general => l10n.settingsCategoryGeneralDesc,
      SettingsSection.apiKeys => l10n.settingsCategoryApiKeysDesc,
      SettingsSection.simulator => l10n.settingsCategorySimulatorDesc,
      SettingsSection.navdata => l10n.settingsCategoryNavdataDesc,
      SettingsSection.ai => l10n.settingsCategoryAiDesc,
      SettingsSection.remote => l10n.settingsCategoryRemoteDesc,
      SettingsSection.about => l10n.settingsCategoryAboutDesc,
    };

/// Builds the section's content widget. Shared by the wide master-detail
/// layout and the narrow full-screen detail page.
Widget buildSettingsSection(SettingsController controller,
    SettingsSection section) {
  switch (section) {
    case SettingsSection.general:
      return GeneralSection(controller: controller);
    case SettingsSection.apiKeys:
      return ApiKeysSection(controller: controller);
    case SettingsSection.simulator:
      return SimulatorSection(controller: controller);
    case SettingsSection.navdata:
      return NavDataSection(controller: controller);
    case SettingsSection.ai:
      return const AiCopilotSection();
    case SettingsSection.remote:
      return RemoteAccessSection(controller: controller);
    case SettingsSection.about:
      return AboutSection(controller: controller);
  }
}

/// Top-level settings screen, designed to live inside a [FloatingWindow].
///
/// Master-detail layout (mirrors IntelliJ / VS Code settings): a vertical
/// section rail on the left, a scrollable content panel on the right. The page
/// is **purely presentational** — the active section is owned by the parent
/// and reported back via [onChangeSection], so a long-lived parent (the
/// floating window host) can keep its place across rebuilds.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.controller,
    required this.section,
    required this.onChangeSection,
  });

  /// The single source of truth for user settings.
  final SettingsController controller;

  /// Which section is currently shown.
  final SettingsSection section;

  /// Invoked when the user picks a different section in the nav rail.
  final ValueChanged<SettingsSection> onChangeSection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Narrow (phone) layout: the master-detail split doesn't fit — show the
    // section menu alone, and push a full-screen detail page when one is
    // picked (with a back arrow to return to the menu).
    final narrow = isNarrowScreen(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // No big horizontal divider — the header sits directly above the body
        // and the visual separation comes from typography + spacing alone,
        // matching the welcome screen's left-card look.
        _SettingsHeader(title: l10n.settingsTitle, subtitle: l10n.settingsDesc),
        Expanded(
          child: narrow
              ? _SettingsNavList(
            selected: section,
            onSelect: (s) => _openSection(context, s),
          )
              : Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // No vertical divider either — the nav rail blends into the
              // same surface as the content. Selection state is communicated
              // by the per-item background, not by a hard rule between the
              // two columns.
              SizedBox(
                width: 232,
                child: _SettingsNavRail(
                  selected: section,
                  onSelect: onChangeSection,
                ),
              ),
              Expanded(child: buildSettingsSection(controller, section)),
            ],
          ),
        ),
      ],
    );
  }

  /// Narrow layout: record the selection (so the menu highlights it after
  /// returning) and push the section as a full-screen detail page.
  void _openSection(BuildContext context, SettingsSection s) {
    onChangeSection(s);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _NarrowSectionPage(controller: controller, section: s),
      ),
    );
  }
}

/// Full-screen page hosting one settings section on narrow screens: a header
/// with a back arrow over the section body.
class _NarrowSectionPage extends StatelessWidget {
  const _NarrowSectionPage({required this.controller, required this.section});

  final SettingsController controller;
  final SettingsSection section;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.surfaceBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 48,
              decoration: BoxDecoration(color: colors.chrome),
              child: Row(
                children: [
                  IconButton(
                    tooltip: MaterialLocalizations
                        .of(context)
                        .backButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                    icon:
                    Icon(Icons.arrow_back_rounded, color: colors.textSecondary),
                  ),
                  Icon(settingsSectionIcon(section),
                      size: 18, color: colors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      settingsSectionTitle(l10n, section).toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            Expanded(child: buildSettingsSection(controller, section)),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsNavRail extends StatelessWidget {
  const _SettingsNavRail({required this.selected, required this.onSelect});

  final SettingsSection selected;
  final ValueChanged<SettingsSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      shrinkWrap: true,
      children: [
        for (final item in _buildNavItems(l10n)) ...[
          _NavButton(
            item: item,
            selected: item.section == selected,
            onTap: () => onSelect(item.section),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

/// Narrow-layout section menu: the same nav rows, full width — the menu IS
/// the landing page; picking one pushes the detail page.
class _SettingsNavList extends StatelessWidget {
  const _SettingsNavList({required this.selected, required this.onSelect});

  final SettingsSection selected;
  final ValueChanged<SettingsSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      children: [
        for (final item in _buildNavItems(l10n)) ...[
          _NavButton(
            item: item,
            selected: item.section == selected,
            onTap: () => onSelect(item.section),
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

List<_NavItem> _buildNavItems(AppLocalizations l10n) =>
    [
      for (final section in SettingsSection.values)
        _NavItem(
          icon: settingsSectionIcon(section),
          label: settingsSectionTitle(l10n, section),
          description: settingsSectionDesc(l10n, section),
          section: section,
        ),
    ];

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.section,
  });

  final IconData icon;
  final String label;
  final String description;
  final SettingsSection section;
}

class _NavButton extends StatefulWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final bg = widget.selected
        ? colors.accent.withValues(alpha: 0.14)
        : _hovering
        ? colors.surfaceLowered.withValues(alpha: 0.7)
        : Colors.transparent;
    final fg = widget.selected ? colors.accent : colors.textPrimary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(widget.item.icon, size: 17, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.item.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: widget.selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      widget.item.description,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: colors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps a section's body in a consistent scroll container with max width.
class SettingsSectionBody extends StatelessWidget {
  const SettingsSectionBody({
    super.key,
    required this.title,
    required this.description,
    required this.children,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/settings_window.dart';
import 'gear_button.dart';

/// The section the welcome content area currently shows. Settings is
/// intentionally absent — it lives in its own floating window launched via the
/// gear menu (see [showGearMenu]) so the entry point is identical on every
/// screen.
enum WelcomeSection { recentFlights, pluginCenter }

/// Non-collapsible, card-style navigation drawer for the welcome screen.
///
/// Top: app logo + name. Middle: nav items (Recent Flights / Plugin Center).
/// Bottom-left: a gear that spins on hover and opens a popup menu (Settings /
/// About / Check for Updates / Help / Exit) — same menu the workspace toolbar
/// gear shows.
class WelcomeNavDrawer extends StatelessWidget {
  const WelcomeNavDrawer({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final WelcomeSection selected;
  final ValueChanged<WelcomeSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LogoHeader(colors: colors, appName: l10n.appName),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                children: [
                  _NavItem(
                    icon: Icons.history_rounded,
                    label: l10n.navRecentFlights,
                    selected: selected == WelcomeSection.recentFlights,
                    onTap: () => onSelect(WelcomeSection.recentFlights),
                  ),
                  const SizedBox(height: 4),
                  _NavItem(
                    icon: Icons.extension_rounded,
                    label: l10n.navPluginCenter,
                    selected: selected == WelcomeSection.pluginCenter,
                    onTap: () => onSelect(WelcomeSection.pluginCenter),
                  ),
                ],
              ),
            ),
          ),
          const _DrawerFooter(),
        ],
      ),
    );
  }
}

class _LogoHeader extends StatelessWidget {
  const _LogoHeader({required this.colors, required this.appName});
  final AppColors colors;
  final String appName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/logo.svg',
            width: 38,
            height: 38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  appName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  l10n.welcomeSubtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final bg = widget.selected
        ? colors.accent.withValues(alpha: 0.16)
        : _hovering
            ? colors.surfaceLowered.withValues(alpha: 0.6)
            : Colors.transparent;
    final fg = widget.selected ? colors.accent : colors.textPrimary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 18, color: fg),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        widget.selected ? FontWeight.w600 : FontWeight.w400,
                    color: fg,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 8, 8),
      child: Row(
        children: [
          Builder(
            builder: (gearContext) =>
                GearButton(
                  tooltip: l10n.gearMenuTooltip,
                  onPressed: () => showGearMenu(gearContext),
                ),
          ),
        ],
      ),
    );
  }
}

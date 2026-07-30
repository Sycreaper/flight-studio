import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../../data/settings/settings_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../shell/app_shell.dart';
import '../shell/tabs/app_tab.dart';
import '../theme/app_colors.dart';
import '../widgets/floating_dialog.dart';
import 'settings_page.dart';

/// The section of the settings tab that should be visible when it opens.
///
/// Lets the gear-menu map "About" / "Settings" entries to specific landing
/// spots without exposing the page's section enum.
enum SettingsLanding { general, simulator, navdata, ai, remote, about }

/// Carries the user [SettingsController] (theme/locale/BYOK/…) down to any
/// widget below [FlightStudioApp]. Looked up via [AppScope.of].
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.settings, required super.child});

  final SettingsController settings;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope above this widget');
    return scope!;
  }

  /// Convenience for callers that only want the settings controller.
  static SettingsController settingsOf(BuildContext context) =>
      of(context).settings;

  @override
  bool updateShouldNotify(AppScope oldWidget) => settings != oldWidget.settings;
}

// ─── Gear menu ──────────────────────────────────────────────────────────────

/// The set of actions the gear popup menu offers.
enum GearMenuAction { settings, about, checkUpdates, help, exit }

/// Shows the gear popup menu anchored to [anchorContext] (the gear button).
///
/// The menu is positioned to **never cover the gear** and to **stay within the
/// window** — it flips above the gear if there isn't enough room below, and its
/// horizontal position is clamped so the right edge never exits the overlay.
Future<void> showGearMenu(BuildContext anchorContext) async {
  final l10n = AppLocalizations.of(anchorContext)!;
  final colors = Theme.of(anchorContext).extension<AppColors>()!;

  final relativeRect = _computeMenuPosition(anchorContext);

  final action = await showMenu<GearMenuAction>(
    context: anchorContext,
    position: relativeRect,
    color: colors.surfaceRaised,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: colors.border),
    ),
    elevation: 12,
    constraints: const BoxConstraints(minWidth: 220),
    items: _buildMenuItems(l10n),
  );

  if (action == null) return;
  if (!anchorContext.mounted) return;
  await _dispatchGearAction(anchorContext, action);
}

/// Compute the menu position using the standard Flutter popup pattern
/// (`RelativeRect.fromRect`). Flutter's `_PopupMenuRouteLayout` reads the
/// anchor rect and places the menu directly below it, left-aligned. If there
/// isn't enough room below, Flutter shifts the menu up automatically — so the
/// menu always stays close to the gear regardless of whether it's at the top
/// or bottom of the window.
RelativeRect _computeMenuPosition(BuildContext anchorContext) {
  final renderBox = anchorContext.findRenderObject() as RenderBox?;
  final overlay =
      Navigator.of(anchorContext).overlay?.context.findRenderObject()
          as RenderBox?;

  if (renderBox == null || overlay == null) {
    return const RelativeRect.fromLTRB(8, 80, 8, 0);
  }

  final buttonRect = Rect.fromPoints(
    renderBox.localToGlobal(Offset.zero, ancestor: overlay),
    renderBox.localToGlobal(
      renderBox.size.bottomRight(Offset.zero),
      ancestor: overlay,
    ),
  );
  // This is exactly what PopupMenuButton does internally. The menu is anchored
  // to the gear button's rect; Flutter positions it below and left-aligned,
  // flipping/shifting as needed to stay on-screen.
  return RelativeRect.fromRect(buttonRect, Offset.zero & overlay.size);
}

List<PopupMenuEntry<GearMenuAction>> _buildMenuItems(AppLocalizations l10n) {
  return [
    PopupMenuItem<GearMenuAction>(
      value: GearMenuAction.settings,
      height: 36,
      child: _MenuItemRow(
        icon: Icons.settings_rounded,
        label: l10n.gearMenuSettings,
      ),
    ),
    PopupMenuItem<GearMenuAction>(
      value: GearMenuAction.about,
      height: 36,
      child: _MenuItemRow(
        icon: Icons.info_outline_rounded,
        label: l10n.gearMenuAbout,
      ),
    ),
    const PopupMenuDivider(height: 1),
    PopupMenuItem<GearMenuAction>(
      value: GearMenuAction.checkUpdates,
      height: 36,
      child: _MenuItemRow(
        icon: Icons.system_update_alt_rounded,
        label: l10n.gearMenuCheckUpdates,
      ),
    ),
    PopupMenuItem<GearMenuAction>(
      value: GearMenuAction.help,
      height: 36,
      child: _MenuItemRow(
        icon: Icons.help_outline_rounded,
        label: l10n.gearMenuHelp,
      ),
    ),
    const PopupMenuDivider(height: 1),
    PopupMenuItem<GearMenuAction>(
      value: GearMenuAction.exit,
      height: 36,
      child: _MenuItemRow(
        icon: Icons.power_settings_new_rounded,
        label: l10n.gearMenuExit,
      ),
    ),
  ];
}

Future<void> _dispatchGearAction(
  BuildContext context,
  GearMenuAction action,
) async {
  final l10n = AppLocalizations.of(context)!;
  switch (action) {
    case GearMenuAction.settings:
      _openSettingsTab(context, SettingsLanding.general);
      break;
    case GearMenuAction.about:
      _openSettingsTab(context, SettingsLanding.about);
      break;
    case GearMenuAction.checkUpdates:
      _showInfoDialog(
        context,
        title: l10n.gearMenuCheckUpdates,
        body: l10n.gearMenuCheckUpdatesNone,
      );
      break;
    case GearMenuAction.help:
      _showInfoDialog(context, title: l10n.gearMenuHelp, body: l10n.comingSoon);
      break;
    case GearMenuAction.exit:
      await windowManager.close();
      break;
  }
}

/// Opens the settings tab — either in the currently-mounted [AppShell] or, if
/// the user is still on the welcome screen, by pushing a new [AppShell] with
/// the settings tab as its initial content.
void _openSettingsTab(BuildContext context, SettingsLanding landing) {
  final settings = AppScope.settingsOf(context);
  final shellState = context.findAncestorStateOfType<AppShellState>();

  if (shellState != null) {
    // Workspace is already open — switch to (or create) the singleton tab.
    shellState.openSettingsTab(section: _mapSection(landing));
    return;
  }

  // Welcome screen — push a workspace that opens directly on the settings tab.
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AppShell(
        settings: settings,
        initialTab: TabType.settings,
        initialSettingsSection: _mapSection(landing),
      ),
    ),
  );
}

SettingsSection _mapSection(SettingsLanding landing) {
  switch (landing) {
    case SettingsLanding.general:
      return SettingsSection.general;
    case SettingsLanding.simulator:
      return SettingsSection.simulator;
    case SettingsLanding.navdata:
      return SettingsSection.navdata;
    case SettingsLanding.ai:
      return SettingsSection.ai;
    case SettingsLanding.remote:
      return SettingsSection.remote;
    case SettingsLanding.about:
      return SettingsSection.about;
  }
}

void _showInfoDialog(
  BuildContext context, {
  required String title,
  required String body,
}) {
  showFloatingDialog(
    context,
    title: title,
    width: 440,
    height: 240,
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SingleChildScrollView(
          child: Text(body, style: const TextStyle(fontSize: 13, height: 1.5)),
        ),
      ),
    ),
  );
}

class _MenuItemRow extends StatelessWidget {
  const _MenuItemRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.textPrimary),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: colors.textPrimary)),
      ],
    );
  }
}

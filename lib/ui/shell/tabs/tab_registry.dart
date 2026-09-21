import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../plugins/extension_registry.dart';
import 'app_tab.dart';

/// Well-known ids for the built-in tab kinds. Third-party tabs use their own
/// plugin-qualified ids (`'<plugin>.<tab>'`) — nothing downstream of the
/// registry ever matches on these constants except shell defaults.
abstract final class TabIds {
  static const String map = 'map';
  static const String flightPlan = 'flightPlan';
  static const String settings = 'settings';
}

/// Describes one kind of main-window tab — the seam a plugin tab uses.
///
/// The label/icon are resolved at render time (via [title] with the active
/// locale) so tabs track locale switches without the controller holding a
/// `BuildContext`. [createContent] builds the tab's centre card; [createToolbar]
/// optionally builds the toolbar row shown above the workspace for this tab
/// kind. [singleton] tabs (e.g. settings) are focus-and-reuse instead of
/// accumulating duplicates.
class TabDescriptor {
  const TabDescriptor({
    required this.id,
    required this.title,
    required this.icon,
    required this.createContent,
    this.createToolbar,
    this.singleton = false,
    this.showInNewTabMenu = true,
    this.showsNavLegend = false,
  });

  /// Stable id persisted inside [AppTab]; `TabIds` for built-ins.
  final String id;

  /// Visible label, resolved with the active locale at render time.
  final String Function(AppLocalizations l10n) title;

  final IconData icon;

  /// Builds the tab's live centre card. Captures whatever per-app state the
  /// kind needs (notifiers, controllers) — AppShell registers descriptors
  /// with closures over its own fields.
  final Widget Function(AppTab tab) createContent;

  /// Builds the toolbar row for this tab kind, or `null` for none.
  final WidgetBuilder? createToolbar;

  /// At most one tab of this kind may exist; opening again selects it.
  final bool singleton;

  /// Whether the tab-bar "+" menu offers this kind.
  final bool showInNewTabMenu;

  /// Whether the map nav-legend bar is shown while a tab of this kind is
  /// selected (map-like tabs that render the shared nav marker layers).
  final bool showsNavLegend;
}

/// Registry of tab kinds. The shell builds every tab — built-in or future
/// plugin — exclusively through lookups here.
class TabRegistry extends ExtensionRegistry<TabDescriptor> {
  TabRegistry() : super(idOf: (d) => d.id);

  /// Convenience alias keeping shell call-sites readable.
  TabDescriptor? descriptorOf(String typeId) => byId(typeId);
}

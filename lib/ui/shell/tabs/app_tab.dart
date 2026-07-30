/// The kind of content a main-window tab hosts.
///
/// `settings` is a singleton — [AppTabController.openOrCreateSettingsTab]
/// guarantees at most one settings tab exists at any time.
enum TabType { map, flightPlan, settings }

/// A single tab in the main window.
///
/// `title` is intentionally omitted — the visible label is resolved from
/// [type] at render time (in `_TabChip.build`) via `AppLocalizations` so it
/// tracks the active locale without the controller needing a `BuildContext`.
class AppTab {
  AppTab({required this.id, required this.type});

  final String id;
  final TabType type;
}

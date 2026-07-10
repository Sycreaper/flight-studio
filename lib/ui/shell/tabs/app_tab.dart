/// The kind of content a main-window tab hosts.
enum TabType { map, flightPlan }

/// A single tab in the main window. Map tabs show the chart + profile; flight
/// plan tabs host the detailed route-building form.
class AppTab {
  AppTab({required this.id, required this.type, required this.title});

  final String id;
  final TabType type;
  String title;
}

import 'tab_registry.dart';

/// A single tab in the main window.
///
/// [typeId] is the id of the registered [TabDescriptor] this tab hosts —
/// `TabIds` constants for built-ins, plugin-qualified ids for future plugin
/// tabs. The title/icon are resolved from the descriptor at render time so
/// labels track the active locale without the controller needing a context.
class AppTab {
  AppTab({required this.id, required this.typeId});

  final String id;
  final String typeId;
}

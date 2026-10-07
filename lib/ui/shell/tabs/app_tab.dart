import 'tab_registry.dart';

/// A single tab in the main window.
///
/// [typeId] is the id of the registered [TabDescriptor] this tab hosts —
/// `TabIds` constants for built-ins, plugin-qualified ids for future plugin
/// tabs. The title/icon are resolved from the descriptor at render time so
/// labels track the active locale without the controller needing a context.
///
/// Chat tabs additionally carry a [chatSessionKey] (the
/// `ChatSessionManager` key of the conversation they mirror) and may have a
/// [titleOverride] — the LLM-generated conversation title, which replaces
/// the descriptor's localized "新对话" default once summarized.
class AppTab {
  AppTab({required this.id, required this.typeId, this.chatSessionKey});

  final String id;
  final String typeId;

  /// `ChatSessionManager` key of the conversation shown in a chat tab.
  final String? chatSessionKey;

  /// Per-tab title that wins over the descriptor's localized title
  /// (LLM-generated conversation titles). Null while untitled.
  String? titleOverride;
}

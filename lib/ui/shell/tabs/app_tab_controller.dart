import 'package:flutter/foundation.dart';

import 'app_tab.dart';
import 'tab_registry.dart';

/// Owns the list of open main-window tabs and the currently selected one.
///
/// Follows the project's ChangeNotifier + MVVM convention; widgets rebuild via
/// `ListenableBuilder` on this controller. Closing the last tab is allowed and
/// yields an empty state (no open tabs).
///
/// Tab **titles are not stored** — they are resolved from the [TabRegistry]
/// descriptor at render time (in the tab bar) via `AppLocalizations`. With a
/// `null` registry (bare construction, e.g. in tests) the controller still
/// works; only singleton enforcement and menu population are unavailable.
class AppTabController extends ChangeNotifier {
  AppTabController({this.registry}) {
    // Always start with a single map tab so the window is never empty.
    _tabs.add(AppTab(id: _nextId(), typeId: TabIds.map));
    _selectedId = _tabs.first.id;
  }

  /// Resolves tab kinds; `null` in bare constructions (tests) — the
  /// controller still works, only singleton enforcement and menu population
  /// are unavailable.
  final TabRegistry? registry;

  final List<AppTab> _tabs = [];
  String? _selectedId;
  int _counter = 0;

  List<AppTab> get tabs => List.unmodifiable(_tabs);
  bool get isEmpty => _tabs.isEmpty;
  AppTab? get selectedOrNull {
    if (_selectedId == null) return null;
    for (final t in _tabs) {
      if (t.id == _selectedId) return t;
    }
    return null;
  }

  String _nextId() => 'tab_${_counter++}';

  bool _isSingleton(String typeId) =>
      registry
          ?.descriptorOf(typeId)
          ?.singleton ?? false;

  /// Opens a new tab of [typeId] and selects it. For singleton kinds
  /// (e.g. settings) an existing tab is selected instead of duplicating —
  /// matching VS Code, where gear → Settings always lands on the same tab.
  void add(String typeId) {
    if (_isSingleton(typeId)) {
      final existing = _tabs
          .cast<AppTab?>()
          .firstWhere((t) => t?.typeId == typeId, orElse: () => null);
      if (existing != null) {
        select(existing.id);
        return;
      }
    }
    final tab = AppTab(id: _nextId(), typeId: typeId);
    _tabs.add(tab);
    _selectedId = tab.id;
    notifyListeners();
  }

  /// Alias emphasising singleton-aware open-or-focus semantics; [add]
  /// enforces the behaviour, this name reads better at call-sites that
  /// "open the settings tab" rather than "create a new tab".
  void openOrCreate(String typeId) => add(typeId);

  /// All open tabs of [typeId], in display order.
  List<AppTab> tabsOfType(String typeId) =>
      [for (final t in _tabs) if (t.typeId == typeId) t];

  /// Moves the tab at [fromIndex] to [toIndex], keeping the selection on the
  /// same tab (by id). Used by the drag-to-reorder gesture in the tab bar —
  /// the open windows / content are not affected, only the visual order.
  void move(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    if (fromIndex < 0 || fromIndex >= _tabs.length) return;
    if (toIndex < 0 || toIndex >= _tabs.length) return;
    final tab = _tabs.removeAt(fromIndex);
    _tabs.insert(toIndex, tab);
    notifyListeners();
  }

  void select(String id) {
    if (_selectedId != id) {
      _selectedId = id;
      notifyListeners();
    }
  }

  /// Closes [id]; re-selects an adjacent tab, or clears the selection when the
  /// last tab is closed (empty state).
  void close(String id) {
    final index = _tabs.indexWhere((t) => t.id == id);
    if (index == -1) return;
    _tabs.removeAt(index);
    if (_tabs.isEmpty) {
      _selectedId = null;
    } else if (_selectedId == id) {
      final newIndex = index.clamp(0, _tabs.length - 1);
      _selectedId = _tabs[newIndex].id;
    }
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';

import 'app_tab.dart';

/// Owns the list of open main-window tabs and the currently selected one.
///
/// Follows the project's ChangeNotifier + MVVM convention; widgets rebuild via
/// `ListenableBuilder` on this controller. Closing the last tab is allowed and
/// yields an empty state (no open tabs).
class AppTabController extends ChangeNotifier {
  AppTabController() {
    // Always start with a single map tab so the window is never empty.
    _tabs.add(AppTab(id: _nextId(), type: TabType.map, title: 'Map'));
    _selectedId = _tabs.first.id;
  }

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

  /// Opens a new tab of [type] and selects it.
  void add(TabType type) {
    final tab = AppTab(
      id: _nextId(),
      type: type,
      title: type == TabType.map ? 'Map' : 'Flight Plan',
    );
    _tabs.add(tab);
    _selectedId = tab.id;
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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The three fixed positions a tool-window drawer can occupy.
enum DrawerSlot { left, right, bottom }

/// Describes one dockable drawer (tool window). Drawers are everything that is
/// NOT a core card (map / form): the flight-plans tree, inspector, profile, etc.
class DrawerPanelData {
  DrawerPanelData({
    required this.id,
    required this.title,
    required this.icon,
    required this.slot,
    required this.content,
    this.visible = true,
    this.width = 280,
    this.height = 220,
  });

  final String id;
  final String title;
  final IconData icon;
  DrawerSlot slot;
  bool visible;
  final WidgetBuilder content;
  final double width;
  final double height;
}

/// Owns the set of dockable drawers and their layout. Widgets rebuild via
/// `ListenableBuilder` on this controller.
///
/// Layout state (slot sizes + each panel's slot & visibility) is **persisted
/// to SharedPreferences** on every change and **restored on construction** so
/// the user's workspace arrangement survives app restarts.
class WorkspaceController extends ChangeNotifier {
  WorkspaceController() {
    _restore();
  }

  static const _prefKey = 'workspace.layout';

  final List<DrawerPanelData> _panels = [];

  // Resizable slot dimensions, managed by drag handles.
  double leftWidth = 280;
  double rightWidth = 280;
  double bottomHeight = 220;

  static const double minCol = 180;
  static const double maxCol = 520;
  static const double minBottom = 120;
  static const double maxBottom = 460;

  void resizeLeft(double delta) {
    leftWidth = (leftWidth + delta).clamp(minCol, maxCol);
    _persist();
    notifyListeners();
  }

  void resizeRight(double delta) {
    rightWidth = (rightWidth + delta).clamp(minCol, maxCol);
    _persist();
    notifyListeners();
  }

  void resizeBottom(double delta) {
    bottomHeight = (bottomHeight + delta).clamp(minBottom, maxBottom);
    _persist();
    notifyListeners();
  }

  List<DrawerPanelData> get panels => List.unmodifiable(_panels);
  List<DrawerPanelData> forSlot(DrawerSlot slot) =>
      _panels.where((p) => p.slot == slot).toList(growable: false);
  List<DrawerPanelData> visibleForSlot(DrawerSlot slot) =>
      _panels.where((p) => p.slot == slot && p.visible).toList(growable: false);

  void register(DrawerPanelData panel) {
    if (_panels.every((p) => p.id != panel.id)) {
      _panels.add(panel);
      _persist();
      notifyListeners();
    }
  }

  void toggle(String id) {
    final p = _byId(id);
    if (p != null) {
      p.visible = !p.visible;
      _persist();
      notifyListeners();
    }
  }

  void moveToSlot(String id, DrawerSlot slot) {
    final p = _byId(id);
    if (p != null && p.slot != slot) {
      p.slot = slot;
      p.visible = true;
      _persist();
      notifyListeners();
    } else if (p != null && !p.visible) {
      p.visible = true;
      _persist();
      notifyListeners();
    }
  }

  void hide(String id) {
    final p = _byId(id);
    if (p != null && p.visible) {
      p.visible = false;
      _persist();
      notifyListeners();
    }
  }

  DrawerPanelData? _byId(String id) {
    for (final p in _panels) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  /// Serialises the layout (sizes + per-panel slot/visibility) to JSON and
  /// writes it to SharedPreferences asynchronously (fire-and-forget).
  void _persist() {
    final layout = {
      'leftWidth': leftWidth,
      'rightWidth': rightWidth,
      'bottomHeight': bottomHeight,
      'panels': {
        for (final p in _panels) p.id: {
          'slot': p.slot.name,
          'visible': p.visible,
        },
      },
    };
    SharedPreferencesAsync()
        .setString(_prefKey, jsonEncode(layout))
        .catchError((_) {});
  }

  /// Reads the persisted layout and applies it to the current state. Called
  /// once from the constructor; subsequent [register] calls for new panels
  /// will also call [_persist] so the stored layout stays in sync.
  Future<void> _restore() async {
    try {
      final prefs = SharedPreferencesAsync();
      final json = await prefs.getString(_prefKey);
      if (json == null) return;
      final data = jsonDecode(json) as Map<String, dynamic>;
      leftWidth = (data['leftWidth'] as num?)?.toDouble() ?? 280;
      rightWidth = (data['rightWidth'] as num?)?.toDouble() ?? 280;
      bottomHeight = (data['bottomHeight'] as num?)?.toDouble() ?? 220;
      final panels = data['panels'] as Map<String, dynamic>?;
      if (panels != null) {
        for (final entry in panels.entries) {
          final id = entry.key;
          final info = entry.value as Map<String, dynamic>;
          final p = _byId(id);
          if (p != null) {
            p.slot = DrawerSlot.values.firstWhere(
                  (s) => s.name == info['slot'],
              orElse: () => p.slot,
            );
            p.visible = info['visible'] as bool? ?? p.visible;
          }
        }
      }
      notifyListeners();
    } on Exception catch (_) {
      // Corrupt or missing layout — silently fall back to defaults.
    }
  }
}

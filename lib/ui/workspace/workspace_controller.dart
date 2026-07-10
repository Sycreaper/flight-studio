import 'package:flutter/material.dart';

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
class WorkspaceController extends ChangeNotifier {
  WorkspaceController();

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
    notifyListeners();
  }

  void resizeRight(double delta) {
    rightWidth = (rightWidth + delta).clamp(minCol, maxCol);
    notifyListeners();
  }

  void resizeBottom(double delta) {
    bottomHeight = (bottomHeight + delta).clamp(minBottom, maxBottom);
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
      notifyListeners();
    }
  }

  /// Toggles a drawer's visibility. If it was hidden, reveal it (keeping its
  /// current slot); if visible, hide it.
  void toggle(String id) {
    final p = _byId(id);
    if (p != null) {
      p.visible = !p.visible;
      notifyListeners();
    }
  }

  /// Moves a drawer to [slot] and makes sure it is visible. Used by the
  /// constrained drag: the only allowed outcomes are the three slots.
  void moveToSlot(String id, DrawerSlot slot) {
    final p = _byId(id);
    if (p != null && p.slot != slot) {
      p.slot = slot;
      p.visible = true;
      notifyListeners();
    } else if (p != null && !p.visible) {
      p.visible = true;
      notifyListeners();
    }
  }

  void hide(String id) {
    final p = _byId(id);
    if (p != null && p.visible) {
      p.visible = false;
      notifyListeners();
    }
  }

  DrawerPanelData? _byId(String id) {
    for (final p in _panels) {
      if (p.id == id) return p;
    }
    return null;
  }
}

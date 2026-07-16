import 'package:flutter/material.dart';

import '../widgets/tool_dock.dart';
import 'resize_handle.dart';
import 'workspace_controller.dart';
import 'workspace_drawer.dart';

/// Renders the full JetBrains-style workspace for a tab:
///
/// ```
/// [LeftDock | Column(Row(leftDrawers | center | rightDrawers), bottomDrawers) | RightDock]
/// ```
///
/// - Left dock top buttons toggle left-slot drawers.
/// - Left dock bottom buttons toggle bottom-slot drawers.
/// - Right dock top buttons toggle right-slot drawers.
/// - Drawers can be dragged between the three slots (constrained drop zones).
class WorkspaceView extends StatefulWidget {
  const WorkspaceView({
    super.key,
    required this.controller,
    required this.center,
  });

  final WorkspaceController controller;
  final Widget center;

  @override
  State<WorkspaceView> createState() => _WorkspaceViewState();
}

class _WorkspaceViewState extends State<WorkspaceView> {
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        return Row(
          children: [
            ToolDock(
              alignment: DockAlignment.left,
              items: [
                ...c.forSlot(DrawerSlot.left).map((p) => DockItem(
                      icon: p.icon,
                      label: p.title,
                      active: p.visible,
                      onTap: () => c.toggle(p.id),
                    )),
              ],
              bottomItems: [
                ...c.forSlot(DrawerSlot.bottom).map((p) => DockItem(
                      icon: p.icon,
                      label: p.title,
                      active: p.visible,
                      onTap: () => c.toggle(p.id),
                    )),
              ],
            ),
            Expanded(child: _buildBody()),
            ToolDock(
              alignment: DockAlignment.right,
              items: [
                ...c.forSlot(DrawerSlot.right).map((p) => DockItem(
                      icon: p.icon,
                      label: p.title,
                      active: p.visible,
                      onTap: () => c.toggle(p.id),
                    )),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    final c = widget.controller;
    final bottom = c.visibleForSlot(DrawerSlot.bottom);
    return Padding(
      padding: const EdgeInsets.all(_gap),
      child: Column(
        children: [
          Expanded(child: _buildMainRow()),
          if (bottom.isNotEmpty) ResizeHandle(horizontal: false, onDrag: (d) => c.resizeBottom(-d)),
          SizedBox(
            height: bottom.isNotEmpty ? c.bottomHeight : 10,
            child: _buildBottom(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainRow() {
    final c = widget.controller;
    final left = c.visibleForSlot(DrawerSlot.left);
    final right = c.visibleForSlot(DrawerSlot.right);
    final hasLeft = left.isNotEmpty;
    final hasRight = right.isNotEmpty;
    // When both side columns plus handles exceed the available width, shrink
    // the columns proportionally so the row never overflows.
    return LayoutBuilder(builder: (context, constraints) {
      const handleW = 8.0;
      final handles = (hasLeft ? handleW : 0) + (hasRight ? handleW : 0);
      final desired =
          (hasLeft ? c.leftWidth : 0) + (hasRight ? c.rightWidth : 0);
      final forCols = (constraints.maxWidth - handles).clamp(0.0, double.infinity);
      final scale = (desired > forCols && desired > 0)
          ? (forCols / desired)
          : 1.0;
      final leftW = hasLeft ? (c.leftWidth * scale) : 10.0;
      final rightW = hasRight ? (c.rightWidth * scale) : 10.0;
      return Row(
        children: [
          _slotColumn(DrawerSlot.left, left, leftW),
          if (hasLeft)
            ResizeHandle(horizontal: true, onDrag: (d) => c.resizeLeft(d)),
          Expanded(child: widget.center),
          if (hasRight)
            ResizeHandle(horizontal: true, onDrag: (d) => c.resizeRight(-d)),
          _slotColumn(DrawerSlot.right, right, rightW),
        ],
      );
    });
  }

  /// Renders a slot column. When the slot holds visible drawers they fill it;
  /// when empty it is a thin always-present drop target so the slot can still
  /// receive a dragged drawer.
  Widget _slotColumn(
      DrawerSlot slot, List<DrawerPanelData> panels, double width) {
    final hasContent = panels.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: width,
      child: DrawerDropZone(
        slot: slot,
        controller: widget.controller,
        child: hasContent
            ? Column(
                children: [
                  for (int i = 0; i < panels.length; i++) ...[
                    if (i > 0) const SizedBox(height: _gap),
                    Expanded(
                      child: WorkspaceDrawer(
                        panel: panels[i],
                        onHide: () => widget.controller.hide(panels[i].id),
                      ),
                    ),
                  ],
                ],
              )
            : const SizedBox.expand(),
      ),
    );
  }

  Widget _buildBottom() {
    final c = widget.controller;
    final panels = c.visibleForSlot(DrawerSlot.bottom);
    final hasContent = panels.isNotEmpty;
    return DrawerDropZone(
      slot: DrawerSlot.bottom,
      controller: c,
      child: hasContent
          ? Row(
              children: [
                for (int i = 0; i < panels.length; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  Expanded(
                    child: WorkspaceDrawer(
                      panel: panels[i],
                      onHide: () => c.hide(panels[i].id),
                    ),
                  ),
                ],
              ],
            )
          : const SizedBox.expand(),
    );
  }
}

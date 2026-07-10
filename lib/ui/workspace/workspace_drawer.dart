import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'workspace_controller.dart';

/// A single dockable drawer rendered inside a workspace slot. Its header is a
/// drag handle: holding the left mouse button and dragging moves the drawer to
/// another slot (left / right / bottom) — the only allowed drop targets.
class WorkspaceDrawer extends StatelessWidget {
  const WorkspaceDrawer({
    super.key,
    required this.panel,
    required this.onHide,
  });

  final DrawerPanelData panel;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Draggable header (drag handle).
          LongPressDraggable<DrawerPanelData>(
            data: panel,
            delay: const Duration(milliseconds: 120),
            feedback: Material(
              color: Colors.transparent,
              child: _DragFeedback(title: panel.title),
            ),
            childWhenDragging: Opacity(
              opacity: 0.4,
              child: _HeaderBar(
                title: panel.title,
                colors: colors,
                onHide: onHide,
              ),
            ),
            child: _HeaderBar(
              title: panel.title,
              colors: colors,
              onHide: onHide,
            ),
          ),
          Expanded(child: panel.content(context)),
        ],
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.title,
    required this.colors,
    required this.onHide,
  });
  final String title;
  final AppColors colors;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        color: colors.surfaceRaised,
        child: Row(
          children: [
            Icon(Icons.drag_indicator_rounded,
                size: 15, color: colors.textDisabled),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: colors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: 'Hide',
              onPressed: onHide,
              icon: const Icon(Icons.close_rounded, size: 14),
              color: colors.textDisabled,
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.accent, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.drag_indicator_rounded,
              size: 15, color: colors.accent),
          const SizedBox(width: 6),
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  color: colors.accent,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// A drop zone wrapping a workspace slot. Highlights when a drawer is dragged
/// over it and repositions the drawer on drop.
class DrawerDropZone extends StatefulWidget {
  const DrawerDropZone({
    super.key,
    required this.slot,
    required this.controller,
    required this.child,
  });

  final DrawerSlot slot;
  final WorkspaceController controller;
  final Widget child;

  @override
  State<DrawerDropZone> createState() => _DrawerDropZoneState();
}

class _DrawerDropZoneState extends State<DrawerDropZone> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return DragTarget<DrawerPanelData>(
      onWillAcceptWithDetails: (details) {
        setState(() => _hovering = true);
        return details.data.slot != widget.slot;
      },
      onLeave: (_) => setState(() => _hovering = false),
      onAcceptWithDetails: (details) {
        widget.controller.moveToSlot(details.data.id, widget.slot);
        setState(() => _hovering = false);
      },
      builder: (context, candidate, rejected) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: _hovering
                ? Border.all(color: colors.accent, width: 2)
                : null,
            color: _hovering
                ? colors.accent.withValues(alpha: 0.08)
                : null,
          ),
          child: Padding(
            padding: _hovering ? const EdgeInsets.all(3) : EdgeInsets.zero,
            child: widget.child,
          ),
        );
      },
    );
  }
}

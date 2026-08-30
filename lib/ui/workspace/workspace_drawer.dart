import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'workspace_controller.dart';

/// Resolves a panel's visible title from its [id] at render time, so the label
/// tracks the active locale without the controller needing a `BuildContext`.
/// Falls back to [DrawerPanelData.title] for custom/future panels whose id is
/// not one of the three defaults.
String _resolvePanelTitle(BuildContext context, DrawerPanelData panel) {
  final l10n = AppLocalizations.of(context)!;
  switch (panel.id) {
    case 'search':
      return l10n.panelSearch;
    case 'flight_plans':
      return l10n.panelFlightPlans;
    case 'inspector':
      return l10n.panelInspector;
    case 'profile':
      return l10n.panelProfile;
    default:
      return panel.title;
  }
}

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
          // Header row: the drag handle fills the available width so the user
          // can grab anywhere except the close button to drag the drawer. The
          // close button lives OUTSIDE the [LongPressDraggable] so its tap is
          // never swallowed by the long-press recogniser.
          Container(
            height: 32,
            color: colors.surfaceRaised,
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              children: [
                Expanded(
                  child: LongPressDraggable<DrawerPanelData>(
                    data: panel,
                    delay: const Duration(milliseconds: 220),
                    feedback: Material(
                      color: Colors.transparent,
                      child: _DragFeedback(panel: panel),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.4,
                      child: _DragHandleLabel(panel: panel),
                    ),
                    child: _DragHandleLabel(panel: panel),
                  ),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context)!.hidePanel,
                  onPressed: onHide,
                  icon: const Icon(Icons.close_rounded, size: 14),
                  color: colors.textDisabled,
                  constraints: const BoxConstraints(
                      minWidth: 22, minHeight: 22),
                  padding: const EdgeInsets.only(right: 8),
                ),
              ],
            ),
          ),
          Expanded(child: panel.content(context)),
        ],
      ),
    );
  }
}

/// Just the icon + uppercase title — the draggable label inside the header.
///
/// The title is resolved from [panel.id] at build time via
/// [_resolvePanelTitle] so it follows locale changes.
///
/// The outer `Container(color: …)` is critical: `Draggable`'s internal
/// `GestureDetector` defaults to `HitTestBehavior.deferToChild`, so without a
/// coloured (or `ColoredBox`-backed) ancestor the drag area would not accept
/// hits and the drawer couldn't be moved. `Colors.transparent` is enough —
/// `ColoredBox.hitTestSelf` always returns `true` regardless of opacity.
class _DragHandleLabel extends StatelessWidget {
  const _DragHandleLabel({required this.panel});

  final DrawerPanelData panel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final title = _resolvePanelTitle(context, panel);
    return Container(
      color: Colors.transparent,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
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
          ],
        ),
      ),
    );
  }
}

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.panel});

  final DrawerPanelData panel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final title = _resolvePanelTitle(context, panel);
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

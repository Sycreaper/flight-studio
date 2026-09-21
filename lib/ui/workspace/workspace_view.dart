import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../adaptive/breakpoints.dart';
import '../panels/inspector_service.dart';
import '../theme/app_colors.dart';
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
///
/// **Narrow (phone) layout** — drawers never dock. All panels collapse into
/// the single left icon rail; tapping an icon pushes the drawer as a
/// full-screen route (header + content, ✕ to dismiss). Slot columns, resize
/// handles and drag-and-drop are wide-screen-only.
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

  /// Panel currently open as a full-screen overlay (narrow layout only).
  String? _openPanelId;

  @override
  void initState() {
    super.initState();
    // Auto-open the inspector drawer when a point gets inspected (LNM shows
    // its Information dock on demand too).
    InspectorService.instance.addListener(_onInspected);
  }

  @override
  void dispose() {
    InspectorService.instance.removeListener(_onInspected);
    super.dispose();
  }

  void _onInspected() {
    if (InspectorService.instance.point == null) return;
    final inspector = _inspectorPanel();
    if (inspector == null) return;
    if (isNarrowScreen(context)) {
      // Narrow: open as a full-screen overlay (only if none already open).
      if (_openPanelId == null) _openNarrowDrawer(inspector);
    } else {
      widget.controller.show(inspector.id);
    }
  }

  DrawerPanelData? _inspectorPanel() {
    for (final p in widget.controller.panels) {
      if (p.id == 'inspector') return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (isNarrowScreen(context)) return _buildNarrow(context);
        return _buildWide(context);
      },
    );
  }

  // ── Narrow (phone) layout ────────────────────────────────────────────────

  Widget _buildNarrow(BuildContext context) {
    final c = widget.controller;
    // One icon rail for EVERY registered panel — slots are meaningless here.
    final items = [
      for (final p in c.panels)
        DockItem(
          icon: p.icon,
          label: resolvePanelTitle(context, p),
          active: _openPanelId == p.id,
          onTap: () => _openNarrowDrawer(p),
        ),
    ];
    return Row(
      children: [
        ToolDock(alignment: DockAlignment.left, items: items),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(_gap),
            child: widget.center,
          ),
        ),
      ],
    );
  }

  /// Pushes [panel] as a full-screen route; the rail button stays highlighted
  /// (via [_openPanelId]) until it pops.
  void _openNarrowDrawer(DrawerPanelData panel) {
    setState(() => _openPanelId = panel.id);
    Navigator.of(context)
        .push(_NarrowDrawerRoute(panel: panel))
        .then((_) {
      if (mounted) setState(() => _openPanelId = null);
    });
  }

  // ── Wide (desktop / tablet) layout ───────────────────────────────────────

  Widget _buildWide(BuildContext context) {
    final c = widget.controller;
    // Localized toggle labels (dock tooltips) resolved at render time.
    String label(DrawerPanelData p) =>
        resolvePanelTitle(context, p);
    return Row(
      children: [
        ToolDock(
          alignment: DockAlignment.left,
          items: [
            ...c.forSlot(DrawerSlot.left).map((p) =>
                DockItem(
                  icon: p.icon,
                  label: label(p),
                  active: p.visible,
                  onTap: () => c.toggle(p.id),
                )),
          ],
          bottomItems: [
            ...c.forSlot(DrawerSlot.bottom).map((p) =>
                DockItem(
                  icon: p.icon,
                  label: label(p),
                  active: p.visible,
                  onTap: () => c.toggle(p.id),
                )),
          ],
        ),
        Expanded(child: _buildBody()),
        ToolDock(
          alignment: DockAlignment.right,
          items: [
            ...c.forSlot(DrawerSlot.right).map((p) =>
                DockItem(
                  icon: p.icon,
                  label: label(p),
                  active: p.visible,
                  onTap: () => c.toggle(p.id),
                )),
          ],
        ),
      ],
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

/// Full-screen route hosting one drawer panel on narrow screens. Slides up
/// slightly and fades in; covers the entire screen (opaque), dismissed by the
/// header ✕ (or the system back gesture).
class _NarrowDrawerRoute extends PageRouteBuilder<void> {
  _NarrowDrawerRoute({required DrawerPanelData panel})
      : super(
    opaque: true,
    barrierDismissible: false,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, _, _) => _NarrowDrawerPage(panel: panel),
    transitionsBuilder: (_, animation, _, child) =>
        SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(opacity: animation, child: child),
        ),
  );
}

/// Header (icon + localized title + close) over the panel's full content.
class _NarrowDrawerPage extends StatelessWidget {
  const _NarrowDrawerPage({required this.panel});

  final DrawerPanelData panel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SafeArea(
      child: Material(
        color: colors.surfaceBase,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 48,
              decoration: BoxDecoration(color: colors.chrome),
              padding: const EdgeInsets.only(left: 6),
              child: Row(
                children: [
                  Icon(panel.icon, size: 18, color: colors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      resolvePanelTitle(context, panel).toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: AppLocalizations.of(context)!.hidePanel,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
            Expanded(child: panel.content(context)),
          ],
        ),
      ),
    );
  }
}




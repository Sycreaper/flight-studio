import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/settings_window.dart';
import '../../theme/app_colors.dart';
import '../../welcome/widgets/gear_button.dart';
import '../window_chrome.dart';
import 'app_tab.dart';
import 'app_tab_controller.dart';
import 'tab_registry.dart';

/// A horizontal tab strip. Tabs flow on the left (scrollable); the "+"
/// affordance sits to the RIGHT of all tabs and stays fixed at the strip end.
class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.controller, this.onHome});

  final AppTabController controller;

  /// Invoked when the user clicks the "back to welcome" home button. When
  /// `null`, the button is not shown.
  final VoidCallback? onHome;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return WindowDragArea(
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: colors.chrome,
        ),
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return Row(
              children: [
                Expanded(
                  child: controller.isEmpty
                      ? const SizedBox.shrink()
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          itemCount: controller.tabs.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 6),
                          itemBuilder: (context, i) {
                            final tab = controller.tabs[i];
                            final selected =
                                tab.id == controller.selectedOrNull?.id;
                            return _ReorderableTabChip(
                              index: i,
                              tab: tab,
                              descriptor: controller.registry
                                  ?.descriptorOf(tab.typeId),
                              selected: selected,
                              onTap: () => controller.select(tab.id),
                              onClose: () => controller.close(tab.id),
                              onReorder: (from, to) =>
                                  controller.move(from, to),
                            );
                          },
                        ),
                ),
                const SizedBox(width: 2),
                _AddTabButton(controller: controller),
                if (onHome != null) ...[
                  const SizedBox(width: 2),
                  Tooltip(
                    message: l10n.toolbarHome,
                    child: IconButton(
                      onPressed: onHome,
                      icon: Icon(Icons.home_rounded,
                          size: 18, color: colors.textSecondary),
                      hoverColor: colors.accent.withValues(alpha: 0.12),
                      constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
                // Gear button — visible on ALL tabs (map, form, settings).
                const SizedBox(width: 2),
                Builder(
                  builder: (gearCtx) =>
                      GearButton(
                        tooltip: l10n.gearMenuTooltip,
                        size: 18,
                        onPressed: () =>
                            showGearMenu(gearCtx),
                      ),
                ),
                // Reserve space for the caption controls overlay so the "+"
                // sits immediately to its left.
                const SizedBox(width: kCaptionWidth),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Wraps a [_TabChip] in a [LongPressDraggable] + [DragTarget] pair so the
/// user can press-and-hold a tab to drag it onto another tab and reorder the
/// list. The gesture fires after a ~250 ms hold so it never conflicts with
/// the outer [WindowDragArea]'s immediate pan recogniser — the user must hold
/// still for a moment before the reorder-drag begins.
class _ReorderableTabChip extends StatefulWidget {
  const _ReorderableTabChip({
    required this.index,
    required this.tab,
    required this.descriptor,
    required this.selected,
    required this.onTap,
    required this.onClose,
    required this.onReorder,
  });

  final int index;
  final AppTab tab;
  final TabDescriptor? descriptor;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final void Function(int from, int to) onReorder;

  @override
  State<_ReorderableTabChip> createState() => _ReorderableTabChipState();
}

class _ReorderableTabChipState extends State<_ReorderableTabChip> {
  bool _hoveringAsDropTarget = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return LongPressDraggable<int>(
      data: widget.index,
      delay: const Duration(milliseconds: 250),
      feedback: Material(
        color: Colors.transparent,
        child: _TabChip(
          tab: widget.tab,
          descriptor: widget.descriptor,
          selected: true,
          onTap: () {},
          onClose: () {},
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _TabChip(
          tab: widget.tab,
          descriptor: widget.descriptor,
          selected: widget.selected,
          onTap: () {},
          onClose: () {},
        ),
      ),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) {
          final accept = details.data != widget.index;
          if (accept) setState(() => _hoveringAsDropTarget = true);
          return accept;
        },
        onLeave: (_) => setState(() => _hoveringAsDropTarget = false),
        onAcceptWithDetails: (details) {
          setState(() => _hoveringAsDropTarget = false);
          widget.onReorder(details.data, widget.index);
        },
        builder: (context, candidate, rejected) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: _hoveringAsDropTarget
                  ? Border.all(color: colors.accent, width: 1.5)
                  : null,
            ),
            child: _TabChip(
              tab: widget.tab,
              descriptor: widget.descriptor,
              selected: widget.selected,
              onTap: widget.onTap,
              onClose: widget.onClose,
            ),
          );
        },
      ),
    );
  }
}

/// A rounded-rectangle tab. Only the icon + label show by default. The close
/// glyph appears on hover. The currently selected tab carries an orange border;
/// non-selected tabs gain a soft dark shadow when hovered.
class _TabChip extends StatefulWidget {
  const _TabChip({
    required this.tab,
    required this.descriptor,
    required this.selected,
    required this.onTap,
    required this.onClose,
  });

  final AppTab tab;

  /// Resolved from the shell's [TabRegistry]; `null` when the controller was
  /// constructed without one (bare tests) — falls back to a generic look.
  final TabDescriptor? descriptor;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  State<_TabChip> createState() => _TabChipState();
}

class _TabChipState extends State<_TabChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final fg = widget.selected ? colors.accent : colors.textPrimary;

    final border = widget.selected
        ? Border.all(color: colors.accent, width: 1.2)
        : Border.all(color: Colors.transparent);

    final shadow = (!widget.selected && _hovering)
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ]
        : const <BoxShadow>[];

    // Selected tab: flat orange-tinted fill inside the orange border.
    // Non-selected: flat background with a soft shadow on hover.
    final bg = widget.selected
        ? colors.accent.withValues(alpha: 0.12)
        : (_hovering
            ? colors.surfaceRaised.withValues(alpha: 0.7)
            : Colors.transparent);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.only(left: 10, right: 8),
          decoration: BoxDecoration(
            color: bg,
            border: border,
            borderRadius: BorderRadius.circular(8),
            boxShadow: shadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.descriptor?.icon ?? Icons.tab_rounded,
                size: 15,
                color: fg,
              ),
              const SizedBox(width: 7),
              Text(
                _tabTitle(
                  widget.descriptor,
                  widget.tab.typeId,
                  l10n,
                  titleOverride: widget.tab.titleOverride,
                ),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                  widget.selected ? FontWeight.w600 : FontWeight.w400,
                  color: fg,
                ),
              ),
              const SizedBox(width: 6),
              // Close glyph: reserved slot, visible only on hover.
              _CloseGlyph(
                visible: _hovering,
                onTap: widget.onClose,
                color: colors.textSecondary,
                hoverColor: colors.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CloseGlyph extends StatefulWidget {
  const _CloseGlyph({
    required this.visible,
    required this.onTap,
    required this.color,
    required this.hoverColor,
  });

  final bool visible;
  final VoidCallback onTap;
  final Color color;
  final Color hoverColor;

  @override
  State<_CloseGlyph> createState() => _CloseGlyphState();
}

class _CloseGlyphState extends State<_CloseGlyph> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return AnimatedOpacity(
      opacity: widget.visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 120),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: _hover
                  ? colors.surfaceLowered.withValues(alpha: 0.9)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(
              Icons.close_rounded,
              size: 13,
              color: _hover ? widget.hoverColor : widget.color,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddTabButton extends StatelessWidget {
  const _AddTabButton({required this.controller});
  final AppTabController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    // Offer every registered tab kind flagged for the "+" menu; fall back to
    // the built-in pair when the controller runs without a registry.
    final registered =
    controller.registry?.all.where((d) => d.showInNewTabMenu).toList();
    final kinds = registered != null && registered.isNotEmpty
        ? registered
        .map((d) => (d.id, d.icon, d.title.call(l10n)))
        .toList()
        : <(String, IconData, String)>[
      (TabIds.map, Icons.map_outlined, l10n.newMapTab),
      (TabIds.flightPlan, Icons.description_outlined, l10n.newFlightPlanTab),
    ];
    return PopupMenuButton<String>(
      tooltip: l10n.addTab,
      icon: Icon(Icons.add_rounded, size: 20, color: colors.textSecondary),
      iconColor: Colors.transparent,
      color: colors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.border),
      ),
      elevation: 8,
      padding: EdgeInsets.zero,
      menuPadding: const EdgeInsets.symmetric(vertical: 4),
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      onSelected: (typeId) => controller.add(typeId),
      itemBuilder: (context) => [
        for (final (id, icon, label) in kinds)
          PopupMenuItem(
            value: id,
            child: _MenuItemRow(icon: icon, label: label),
          ),
      ],
    );
  }
}

class _MenuItemRow extends StatelessWidget {
  const _MenuItemRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colors.accent),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: colors.textPrimary)),
      ],
    );
  }
}

/// Resolves a tab's visible label: a per-tab override (LLM-generated
/// conversation titles) wins over the descriptor's localized title, so
/// labels track the active locale unless explicitly renamed.
String _tabTitle(
    TabDescriptor? descriptor,
    String typeId,
    AppLocalizations l10n, {
    String? titleOverride,
    }) {
  if (titleOverride != null && titleOverride.isNotEmpty) return titleOverride;
  final title = descriptor?.title;
  if (title != null) return title(l10n);
  return typeId;
}

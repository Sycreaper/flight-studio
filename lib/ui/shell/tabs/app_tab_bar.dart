import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../window_chrome.dart';
import 'app_tab.dart';
import 'app_tab_controller.dart';

/// A horizontal tab strip. Tabs flow on the left (scrollable); the "+"
/// affordance sits to the RIGHT of all tabs and stays fixed at the strip end.
class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.controller});

  final AppTabController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
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
                            return _TabChip(
                              tab: tab,
                              selected: selected,
                              onTap: () => controller.select(tab.id),
                              onClose: () => controller.close(tab.id),
                            );
                          },
                        ),
                ),
                const SizedBox(width: 2),
                _AddTabButton(controller: controller),
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

/// A rounded-rectangle tab. Only the icon + label show by default. The close
/// glyph appears on hover. The currently selected tab carries an orange border;
/// non-selected tabs gain a soft dark shadow when hovered.
class _TabChip extends StatefulWidget {
  const _TabChip({
    required this.tab,
    required this.selected,
    required this.onTap,
    required this.onClose,
  });

  final AppTab tab;
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
                widget.tab.type == TabType.map
                    ? Icons.map_outlined
                    : Icons.description_outlined,
                size: 15,
                color: fg,
              ),
              const SizedBox(width: 7),
              Text(
                widget.tab.title,
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
    return PopupMenuButton<TabType>(
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
      onSelected: (type) => controller.add(type),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: TabType.map,
          child: _MenuItemRow(
              icon: Icons.map_outlined, label: l10n.newMapTab),
        ),
        PopupMenuItem(
          value: TabType.flightPlan,
          child: _MenuItemRow(
              icon: Icons.description_outlined,
              label: l10n.newFlightPlanTab),
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

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A single entry in a [ToolDock].
class DockItem {
  const DockItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final int? badge;
}

/// A JetBrains-style tool-window stripe (dock). A thin vertical column of icon
/// buttons flanking the editor; each toggles a side drawer. Background matches
/// the status bar ([AppColors.chrome]).
class ToolDock extends StatelessWidget {
  const ToolDock({
    super.key,
    required this.items,
    this.bottomItems = const [],
    this.alignment = DockAlignment.left,
  });

  final List<DockItem> items;
  final List<DockItem> bottomItems;
  final DockAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: 46,
      decoration: BoxDecoration(color: colors.chrome),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...items.map((i) => _DockButton(item: i, alignment: alignment)),
          const Spacer(),
          ...bottomItems.map((i) => _DockButton(item: i, alignment: alignment)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

enum DockAlignment { left, right }

class _DockButton extends StatefulWidget {
  const _DockButton({required this.item, required this.alignment});
  final DockItem item;
  final DockAlignment alignment;

  @override
  State<_DockButton> createState() => _DockButtonState();
}

class _DockButtonState extends State<_DockButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final active = widget.item.active;
    final fg = active
        ? colors.accent
        : (_hovering ? colors.textPrimary : colors.textSecondary);
    final bg = active
        ? colors.accent.withValues(alpha: 0.12)
        : (_hovering
            ? colors.surfaceBase.withValues(alpha: 0.5)
            : Colors.transparent);

    final barAlign = widget.alignment == DockAlignment.left
        ? Alignment.centerLeft
        : Alignment.centerRight;

    return Tooltip(
      message: widget.item.label,
      waitDuration: const Duration(milliseconds: 300),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.item.onTap,
          child: Container(
            height: 44,
            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (active)
                  Align(
                    alignment: barAlign,
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: colors.accent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                Icon(widget.item.icon, size: 19, color: fg),
                if (widget.item.badge != null)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: colors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${widget.item.badge}',
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

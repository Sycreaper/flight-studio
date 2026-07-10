import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A draggable splitter between two adjacent cards. On hover it shows an orange
/// glow (no border) and a resize cursor; holding the left mouse button and
/// dragging resizes the neighbouring cards. [horizontal] selects a left↔right
/// handle (`<-->`) versus an up↕down handle.
class ResizeHandle extends StatefulWidget {
  const ResizeHandle({
    super.key,
    required this.horizontal,
    required this.onDrag,
  });

  final bool horizontal;
  final void Function(double delta) onDrag;

  @override
  State<ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<ResizeHandle> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final cursor = widget.horizontal
        ? SystemMouseCursors.resizeLeftRight
        : SystemMouseCursors.resizeUpDown;
    return MouseRegion(
      cursor: cursor,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (d) =>
            widget.onDrag(widget.horizontal ? d.delta.dx : d.delta.dy),
        child: Container(
          width: widget.horizontal ? 8 : double.infinity,
          height: widget.horizontal ? double.infinity : 8,
          decoration: BoxDecoration(
            color: _hovering
                ? colors.accent.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.35),
                      blurRadius: 8,
                    )
                  ]
                : const [],
          ),
        ),
      ),
    );
  }
}

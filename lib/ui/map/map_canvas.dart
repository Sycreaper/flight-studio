import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Placeholder for the central map canvas. Will host `flutter_map` with custom
/// layers (airports, navaids, airways, airspace, route, aircraft) in phase 1+.
class MapCanvas extends StatelessWidget {
  const MapCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Faux ocean/grid backdrop until flutter_map is wired up.
          Positioned.fill(child: CustomPaint(painter: _GridPainter(colors))),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_rounded, size: 48, color: Color(0x55FFFFFF)),
                SizedBox(height: 12),
                Text(
                  'Map',
                  style: TextStyle(
                    color: Color(0x66FFFFFF),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Floating zoom controls (top-right), like IDEA's editor gutter.
          Positioned(
            top: 12,
            right: 12,
            child: _ZoomControls(),
          ),
        ],
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded, size: 18),
            tooltip: 'Zoom in',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Divider(height: 1, color: colors.border),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.remove_rounded, size: 18),
            tooltip: 'Zoom out',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.colors);
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colors.border.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    const step = 40.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

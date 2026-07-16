import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../theme/app_colors.dart';

/// Total width reserved for the three caption buttons (minimize / maximize /
/// close), each ~46px wide. Layouts reserve this much space at their top-right
/// so content never sits under the caption overlay.
const double kCaptionWidth = 46 * 3;

/// Windows-style caption controls (minimize / maximize-or-restore / close),
/// drawn with native-looking glyphs. Theme-aware so it works in both dark and
/// light themes. The close button turns red on hover (Windows behaviour).
class WindowCaptionControls extends StatefulWidget {
  const WindowCaptionControls({super.key});

  @override
  State<WindowCaptionControls> createState() => _WindowCaptionControlsState();
}

class _WindowCaptionControlsState extends State<WindowCaptionControls>
    with WindowListener {
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _refresh();
  }

  Future<void> _refresh() async {
    final max = await windowManager.isMaximized();
    if (mounted && max != _maximized) setState(() => _maximized = max);
  }

  @override
  void onWindowMaximize() => setState(() => _maximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _maximized = false);

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CaptionButton(
            glyph: _CaptionGlyph.minimize,
            onPressed: () => windowManager.minimize(),
          ),
          _CaptionButton(
            glyph:
                _maximized ? _CaptionGlyph.restore : _CaptionGlyph.maximize,
            onPressed: () async {
              if (await windowManager.isMaximized()) {
                windowManager.unmaximize();
              } else {
                windowManager.maximize();
              }
            },
          ),
          _CaptionButton(
            glyph: _CaptionGlyph.close,
            isClose: true,
            onPressed: () => windowManager.close(),
          ),
        ],
      ),
    );
  }
}

enum _CaptionGlyph { minimize, maximize, restore, close }

class _CaptionButton extends StatefulWidget {
  const _CaptionButton({
    required this.glyph,
    required this.onPressed,
    this.isClose = false,
  });

  final _CaptionGlyph glyph;
  final VoidCallback onPressed;
  final bool isClose;

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bg;
    final Color fg;
    if (_hovering && widget.isClose) {
      bg = const Color(0xFFC42B1C); // Windows close red (same in any theme)
      fg = Colors.white;
    } else if (_hovering) {
      // Subtle hover overlay that works on both dark and light backgrounds.
      bg = isDark
          ? Colors.white.withValues(alpha: 0.10)
          : Colors.black.withValues(alpha: 0.07);
      fg = colors.textPrimary;
    } else {
      bg = Colors.transparent;
      fg = colors.textPrimary;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: double.infinity,
          color: bg,
          alignment: Alignment.center,
          child: CustomPaint(
            size: const Size(12, 12),
            painter: _GlyphPainter(glyph: widget.glyph, color: fg),
          ),
        ),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({required this.glyph, required this.color});
  final _CaptionGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;

    switch (glyph) {
      case _CaptionGlyph.minimize:
        canvas.drawLine(
          Offset(w * 0.22, h * 0.66),
          Offset(w * 0.78, h * 0.66),
          paint,
        );
      case _CaptionGlyph.maximize:
        canvas.drawRect(
          Rect.fromLTRB(w * 0.22, h * 0.26, w * 0.78, h * 0.74),
          paint,
        );
      case _CaptionGlyph.restore:
        canvas.drawRect(
          Rect.fromLTRB(w * 0.24, h * 0.24, w * 0.66, h * 0.62),
          paint,
        );
        canvas.drawRect(
          Rect.fromLTRB(w * 0.34, h * 0.38, w * 0.76, h * 0.76),
          paint,
        );
      case _CaptionGlyph.close:
        canvas.drawLine(Offset(w * 0.26, h * 0.26), Offset(w * 0.74, h * 0.74), paint);
        canvas.drawLine(Offset(w * 0.74, h * 0.26), Offset(w * 0.26, h * 0.74), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.color != color;
}

/// A translucent drag wrapper that lets the user move the (frameless) window by
/// dragging empty areas. Interactive children still receive their taps/drags.
class WindowDragArea extends StatelessWidget {
  const WindowDragArea({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: () async {
        if (await windowManager.isMaximized()) {
          windowManager.unmaximize();
        } else {
          windowManager.maximize();
        }
      },
      child: child,
    );
  }
}

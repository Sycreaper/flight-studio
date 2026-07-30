import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A floating, draggable window rendered as an overlay on top of the app.
///
/// Renders nothing by itself until placed inside a [Stack] (typically the app's
/// root overlay). The window has:
/// - A draggable title bar (drag anywhere on the title to move the window).
/// - A close (✕) button on the right.
/// - A subtle shadow + rounded corners so it reads as a separate surface.
///
/// The window is **not** modal — the underlying app stays interactive. Pass
/// `barrierDismissable: true` (default) to also close on tap-outside.
class FloatingWindow extends StatefulWidget {
  const FloatingWindow({
    super.key,
    required this.title,
    required this.child,
    required this.onClose,
    this.titleIcon = Icons.settings_rounded,
    this.width = 940,
    this.height = 640,
    this.minWidth = 480,
    this.minHeight = 320,
    this.barrierDismissable = true,
    this.initialPosition,
  });

  /// Title shown in the drag handle.
  final String title;

  /// Icon rendered to the left of the title in the drag handle. Defaults to a
  /// gear; callers pass `Icons.balance_rounded` for legal/info dialogs, etc.
  final IconData titleIcon;

  /// Window body. Should fill the available space (typically a `Column` or a
  /// widget with its own scroll view).
  final Widget child;

  /// Invoked when the user clicks the ✕ button or taps the barrier (if
  /// [barrierDismissable] is `true`).
  final VoidCallback onClose;

  final double width;
  final double height;
  final double minWidth;
  final double minHeight;

  /// When `true`, tapping outside the window calls [onClose]. Set to `false`
  /// for windows the user must explicitly dismiss (e.g. critical prompts).
  final bool barrierDismissable;

  /// Optional initial window position. When `null`, the window is centred.
  final Offset? initialPosition;

  @override
  State<FloatingWindow> createState() => _FloatingWindowState();
}

class _FloatingWindowState extends State<FloatingWindow> {
  late Offset _position;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      _position = widget.initialPosition ?? _defaultCenter();
      _initialised = true;
    }
  }

  Offset _defaultCenter() {
    final size = MediaQuery.sizeOf(context);
    return Offset(
      (size.width - widget.width) / 2,
      (size.height - widget.height) / 2,
    );
  }

  void _onPan(DragUpdateDetails details) {
    setState(() {
      var next = _position + details.delta;
      final size = MediaQuery.sizeOf(context);
      // Clamp so at least 80px of the title bar stays visible on every edge —
      // the window can never get lost off-screen.
      final minX = -(widget.width - 80);
      final maxX = size.width - 80;
      final minY = 0.0;
      final maxY = size.height - 44;
      next = Offset(next.dx.clamp(minX, maxX), next.dy.clamp(minY, maxY));
      _position = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Tap-outside-to-close barrier. Sits below the window but above the
        // underlying app content; absorbs taps so they don't reach the app.
        if (widget.barrierDismissable)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onClose,
            child: const SizedBox.expand(),
          )
        else
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withValues(alpha: 0.18),
          ),
        Positioned(
          left: _position.dx,
          top: _position.dy,
          width: widget.width,
          height: widget.height,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderStrong),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 28,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DragHandle(
                    title: widget.title,
                    titleIcon: widget.titleIcon,
                    onPan: _onPan,
                    onClose: widget.onClose,
                  ),
                  // No divider below the title bar — the window body shares
                  // the same surface, so the header reads as part of the
                  // card rather than a separate chrome strip.
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Title bar that doubles as the drag handle. Renders a static gear icon on
/// the left (replacing the previous 6-dot drag indicator), the window title
/// next to it, and the close button on the right. No coloured background bar
/// and no divider — the whole header shares the window body's surface.
///
/// Uses `opaque` hit-test behaviour so the pan gesture is claimed by this
/// widget and does not propagate down to any underlying [WindowDragArea].
class _DragHandle extends StatefulWidget {
  const _DragHandle({
    required this.title,
    required this.titleIcon,
    required this.onPan,
    required this.onClose,
  });

  final String title;
  final IconData titleIcon;
  final ValueChanged<DragUpdateDetails> onPan;
  final VoidCallback onClose;

  @override
  State<_DragHandle> createState() => _DragHandleState();
}

class _DragHandleState extends State<_DragHandle> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return MouseRegion(
      cursor: SystemMouseCursors.move,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: widget.onPan,
        onDoubleTap: () {},
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          // Always transparent — the title bar shares the window body's
          // surface with no visual distinction. The move-cursor on hover is
          // the only affordance that the bar is draggable.
          color: Colors.transparent,
          child: Row(
            children: [
              Icon(widget.titleIcon, size: 16, color: colors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                onPressed: widget.onClose,
                icon: const Icon(Icons.close_rounded, size: 16),
                hoverColor: colors.danger.withValues(alpha: 0.18),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

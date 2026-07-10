import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A settings gear icon that continuously rotates while the pointer hovers
/// over it. Placed at the bottom-left of the welcome nav drawer.
class SpinningGearButton extends StatefulWidget {
  const SpinningGearButton({
    super.key,
    required this.onPressed,
    this.size = 20,
  });

  final VoidCallback onPressed;
  final double size;

  @override
  State<SpinningGearButton> createState() => _SpinningGearButtonState();
}

class _SpinningGearButtonState extends State<SpinningGearButton>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEnter(PointerEnterEvent _) {
    setState(() => _hovering = true);
    _controller.repeat();
  }

  void _onExit(PointerExitEvent _) {
    setState(() => _hovering = false);
    _controller.stop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: RotationTransition(
        turns: _controller,
        child: IconButton(
          onPressed: widget.onPressed,
          tooltip: 'Open settings',
          icon: Icon(
            Icons.settings_rounded,
            size: widget.size,
            color: _hovering ? colors.accent : colors.textDisabled,
          ),
          constraints: BoxConstraints(
              minWidth: widget.size + 8, minHeight: widget.size + 8),
          padding: EdgeInsets.zero,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashRadius: widget.size,
        ),
      ),
    );
  }
}

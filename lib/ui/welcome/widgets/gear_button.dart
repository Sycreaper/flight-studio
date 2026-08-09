import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../data/background_tasks.dart';
import '../../theme/app_colors.dart';

/// A static gear icon used as the affordance for the gear popup menu
/// (Settings / About / Updates / Help / Exit).
///
/// By default the gear is **static** — it no longer spins on hover. Rotation
/// is reserved for the future "background process running" indicator: pass
/// [spinning] `true` (or call [GearButton.setSpinning] via a state key) to
/// start a continuous slow rotation that signals work in progress.
///
/// Click handling is supplied by the caller — typically it opens the gear
/// menu (see `lib/ui/settings/settings_window.dart` → `showGearMenu`).
class GearButton extends StatefulWidget {
  const GearButton({
    super.key,
    required this.onPressed,
    this.tooltip,
    this.spinning = false,
    this.size = 20,
  });

  final VoidCallback onPressed;

  /// Tooltip shown on hover. When `null`, defaults to the platform's
  /// "more" label.
  final String? tooltip;

  /// Whether the gear is currently rotating to indicate a background process.
  /// Defaults to `false` — the gear is purely a static menu affordance unless
  /// something explicitly asks it to spin.
  final bool spinning;

  final double size;

  @override
  State<GearButton> createState() => GearButtonState();
}

/// Public state so a long-lived parent can toggle [spinning] without rebuilding
/// the button with a new key (e.g. when a telemetry stream connects).
class GearButtonState extends State<GearButton> with TickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hovering = false;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _isSpinning = widget.spinning;
    if (_isSpinning) _controller.repeat();
    BackgroundTaskManager.instance.addListener(_onTasksChanged);
    _onTasksChanged();
  }

  void _onTasksChanged() {
    if (!mounted) return;
    final shouldSpin =
        widget.spinning || BackgroundTaskManager.instance.hasActiveTasks;
    if (shouldSpin != _isSpinning) {
      setState(() => _isSpinning = shouldSpin);
    }
    if (shouldSpin && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldSpin && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void didUpdateWidget(covariant GearButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _onTasksChanged();
  }

  void setSpinning(bool value) {
    _onTasksChanged();
  }

  @override
  void dispose() {
    BackgroundTaskManager.instance.removeListener(_onTasksChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onEnter(PointerEnterEvent _) => setState(() => _hovering = true);
  void _onExit(PointerExitEvent _) => setState(() => _hovering = false);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final tooltip =
        widget.tooltip ?? MaterialLocalizations.of(context).moreButtonTooltip;
    final iconColor = _hovering
        ? colors.accent : colors.textSecondary;
    final icon = Icon(
      Icons.settings_rounded,
      size: widget.size,
      color: iconColor,
    );
    final button = IconButton(
      onPressed: widget.onPressed,
      tooltip: tooltip,
      icon: _isSpinning
          ? RotationTransition(turns: _controller, child: icon)
          : icon,
      constraints: BoxConstraints(
        minWidth: widget.size + 12,
        minHeight: widget.size + 12,
      ),
      padding: EdgeInsets.zero,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashRadius: widget.size,
    );
    return MouseRegion(onEnter: _onEnter, onExit: _onExit, child: button);
  }
}

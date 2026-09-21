import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// The bottom status bar: connection state, navdata cycle, cursor/center
/// coordinates and — on the right — UTC time plus live CPU / GPU / memory
/// utilisation. Active background-task progress bars render on the far left
/// (hidden entirely when no task is running).
class StatusBar extends StatelessWidget {
  const StatusBar({
    super.key,
    this.isConnected = false,
    this.dataCycle,
    this.coordinate,
    this.utcTime,
    this.cpuUsage,
    this.gpuUsage,
    this.memoryUsage,
    this.tasks = const [],
  });

  final bool isConnected;

  /// Navdata summary line (e.g. `Nav 17.6k · Fix 250.6k`); `null`/empty hides.
  final String? dataCycle;

  /// Coordinate string (map centre, DMS-formatted).
  final String? coordinate;

  /// Pre-formatted UTC time string.
  final String? utcTime;

  /// CPU utilisation in percent (already sampled), rendered as `CPU 42%`.
  final double? cpuUsage;

  /// GPU utilisation in percent, `null` → `GPU --`.
  final double? gpuUsage;

  /// Memory usage in percent, rendered as `MEM 63%`.
  final double? memoryUsage;

  /// Active background tasks — each renders as a compact progress entry on
  /// the far left of the bar.
  final List<StatusProgressTask> tasks;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      // Stretch to the full window width (Column would otherwise centre the
      // intrinsic-width container, leaving a blank strip on the right), and
      // keep a small inset from the window edge on the left.
      width: double.infinity,
      height: 26,
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(color: colors.chrome),
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: [
          // ── Progress bars (far left) — visible only when tasks run ──────
          for (final task in tasks.take(2)) ...[
            _ProgressEntry(task: task, colors: colors),
            _Divider(),
          ],

          // Connection state.
          _StatusChip(
            connected: isConnected,
            label:
            isConnected ? l10n.statusConnected : l10n.statusDisconnected,
          ),
          if (dataCycle != null && dataCycle!.isNotEmpty) ...[
            _Divider(),
            Flexible(child: _Item(label: dataCycle!, dim: true)),
          ],

          if (coordinate != null && coordinate!.isNotEmpty) ...[
            _Divider(),
            Flexible(
              child: _Item(
                  label: coordinate!, icon: Icons.my_location_rounded),
            ),
          ],

          const Spacer(),

          // ── Live data (right) ──────────────────────────────────────────
          if (utcTime != null) _Item(
              label: utcTime!, icon: Icons.schedule_rounded),
          if (cpuUsage != null) ...[
            _Divider(),
            _Item(
              label: '${l10n.statusCpu} ${cpuUsage!.round()}%',
              icon: Icons.memory_rounded,
              value: cpuUsage,
            ),
          ],
          if (gpuUsage != null) ...[
            _Divider(),
            _Item(
              label: gpuUsage! >= 0
                  ? '${l10n.statusGpu} ${gpuUsage!.round()}%'
                  : '${l10n.statusGpu} --',
              icon: Icons.videogame_asset_rounded,
              value: gpuUsage! >= 0 ? gpuUsage : null,
            ),
          ],
          if (memoryUsage != null) ...[
            _Divider(),
            _Item(
              label: '${l10n.statusMem} ${memoryUsage!.round()}%',
              icon: Icons.dns_rounded,
              value: memoryUsage,
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// A compact progress entry for one background task: radar icon + truncated
/// label + percent + thin progress bar. Fits the 24 px status-bar height.
class _ProgressEntry extends StatelessWidget {
  const _ProgressEntry({required this.task, required this.colors});

  final StatusProgressTask task;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final pct = (task.progress * 100).round();
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            task.isComplete ? Icons.check_circle_rounded : Icons.radar_rounded,
            size: 11,
            color: task.isComplete ? colors.success : colors.accent,
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              task.label,
              style: TextStyle(fontSize: 10.5, color: colors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              width: 44,
              height: 3,
              child: LinearProgressIndicator(
                value: task.progress.clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: colors.surfaceLowered,
                valueColor: AlwaysStoppedAnimation(
                    task.isComplete ? colors.success : colors.accent),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$pct%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// One status-bar data readout. When [value] is set, a thin utilisation bar
/// is drawn under the label — colour shifts to warning past 80 %.
class _Item extends StatelessWidget {
  const _Item({required this.label, this.icon, this.dim = false, this.value});

  final String label;
  final IconData? icon;
  final bool dim;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final color = dim ? colors.textDisabled : colors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (value != null) ...[
            const SizedBox(height: 2),
            SizedBox(
              width: 44,
              height: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: LinearProgressIndicator(
                  value: (value! / 100).clamp(0.0, 1.0),
                  minHeight: 2,
                  backgroundColor: colors.surfaceLowered,
                  valueColor: AlwaysStoppedAnimation(
                    value! >= 80 ? colors.warning : colors.accent,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.connected, required this.label});
  final bool connected;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final dot = connected ? colors.success : colors.textDisabled;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
              boxShadow: connected
                  ? [BoxShadow(color: dot.withValues(alpha: 0.5), blurRadius: 6)]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: 1,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: colors.border,
    );
  }
}

/// Simple data holder for one in-flight background task, decoupled from
/// [BackgroundTaskManager] so the status bar stays presentation-only.
class StatusProgressTask {
  const StatusProgressTask(
      {required this.label, required this.progress, this.isComplete = false});

  final String label;
  final double progress;
  final bool isComplete;
}

/// Simple math helper kept for potential formatting needs.
// ignore: unused_element
double _clamp01(double v) => math.min(1, math.max(0, v));

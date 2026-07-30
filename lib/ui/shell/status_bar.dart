import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// The bottom status bar showing connection state, cursor coordinates, UTC time
/// and system resource usage — modelled on the JetBrains IDEA status bar.
class StatusBar extends StatelessWidget {
  const StatusBar({
    super.key,
    this.isConnected = false,
    this.dataCycle,
    this.coordinate,
    this.utcTime,
    this.cpuUsage,
    this.memoryUsage,
  });

  final bool isConnected;
  final String? dataCycle;
  final String? coordinate;
  final String? utcTime;
  final String? cpuUsage;
  final String? memoryUsage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: colors.chrome,
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusChip(
                  connected: isConnected,
                  label: l10n.statusConnected,
                ),
                if (dataCycle != null && dataCycle!.isNotEmpty) ...[
                  _Divider(),
                  Flexible(
                    child: _Item(label: dataCycle!, dim: true),
                  ),
                ],
              ],
            ),
          ),
          if (coordinate != null) _Divider(),
          if (coordinate != null)
            Flexible(
              child: _Item(
                  label: coordinate!, icon: Icons.my_location_rounded),
            ),
          const Spacer(),
          if (utcTime != null)
            _Item(label: utcTime!, icon: Icons.schedule_rounded),
          if (cpuUsage != null) _Divider(),
          if (cpuUsage != null)
            _Item(
                label: '${l10n.statusCpu} $cpuUsage',
                icon: Icons.memory_rounded),
          if (memoryUsage != null) _Divider(),
          if (memoryUsage != null)
            _Item(label: '${l10n.statusMem} $memoryUsage'),
          const SizedBox(width: 8),
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

class _Item extends StatelessWidget {
  const _Item({required this.label, this.icon, this.dim = false});
  final String label;
  final IconData? icon;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final color = dim ? colors.textDisabled : colors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
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

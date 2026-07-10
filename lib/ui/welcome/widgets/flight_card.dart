import 'package:flutter/material.dart';

import '../../../features/flights/flight_record.dart';
import '../../theme/app_colors.dart';

/// A wide card representing one saved flight. Left: square aircraft thumbnail
/// (falls back to a plane icon when no thumbnail is available). Right: big
/// departure → arrival text with secondary metadata beneath.
class FlightCard extends StatelessWidget {
  const FlightCard({
    super.key,
    required this.flight,
    this.onTap,
  });

  final FlightRecord flight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _AircraftThumb(flight: flight, colors: colors),
              const SizedBox(width: 14),
              Expanded(child: _Details(flight: flight, colors: colors)),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: colors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}

class _AircraftThumb extends StatelessWidget {
  const _AircraftThumb({required this.flight, required this.colors});
  final FlightRecord flight;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final path = flight.aircraftThumbnailPath;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: colors.surfaceLowered,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: path != null
          ? Image.asset(path, fit: BoxFit.cover, errorBuilder: (_, _, _) {
              return _planeIcon();
            })
          : _planeIcon(),
    );
  }

  Widget _planeIcon() => Center(
        child: Transform.rotate(
          angle: -0.5,
          child: Icon(Icons.flight_rounded,
              size: 28, color: colors.accent.withValues(alpha: 0.7)),
        ),
      );
}

class _Details extends StatelessWidget {
  const _Details({required this.flight, required this.colors});
  final FlightRecord flight;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final sub = <String>[
      flight.aircraftName,
      if (flight.airlineName.isNotEmpty) flight.airlineName,
      if (flight.cruiseAltitudeFt != null)
        'FL ${(flight.cruiseAltitudeFt! ~/ 100).toString().padLeft(3, '0')}',
      if (flight.durationMinutes != null) _formatDuration(flight.durationMinutes!),
    ].join('  \u00b7  ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          flight.route,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          sub,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
      ],
    );
  }

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}

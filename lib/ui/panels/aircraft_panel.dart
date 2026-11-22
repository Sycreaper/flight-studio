import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../sim/sim_connection_service.dart';
import '../../sim/simulator_connector.dart';
import '../settings/settings_window.dart';
import '../theme/app_colors.dart';
import '../widgets/fact_row.dart';

/// Right-drawer panel showing the live aircraft state from the simulator
/// link: connection status plus the fact-sheet table (the inspector's
/// airport-dossier style) grouped into Position / Speed / Attitude /
/// Autopilot. Missing values render as "—" (aircraft vary in what they
/// expose); while disconnected the panel shows a hint and a shortcut to
/// Settings → Simulator.
class AircraftPanel extends StatelessWidget {
  const AircraftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: SimConnectionService.instance,
      builder: (context, _) {
        final service = SimConnectionService.instance;
        final telemetry = service.telemetry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusHeader(state: service.state, error: service.error),
            Expanded(
              child: telemetry == null
                  ? _EmptyState(l10n: l10n, colors: colors)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _GroupTitle(l10n.aircraftGroupPosition),
                          FactRow(
                            label: l10n.aircraftLatitude,
                            value: _lat(telemetry.latitude),
                          ),
                          FactRow(
                            label: l10n.aircraftLongitude,
                            value: _lon(telemetry.longitude),
                          ),
                          FactRow(
                            label: l10n.aircraftAltitudeMsl,
                            value: _num(telemetry.altitudeFt, ' ft'),
                          ),
                          FactRow(
                            label: l10n.aircraftAltitudeAgl,
                            value: _num(telemetry.altitudeAglFt, ' ft'),
                          ),
                          _GroupTitle(l10n.aircraftGroupSpeed),
                          FactRow(
                            label: l10n.aircraftGroundSpeed,
                            value: _num(telemetry.groundSpeedKt, ' kt'),
                          ),
                          FactRow(
                            label: l10n.aircraftIas,
                            value: _num(telemetry.indicatedAirspeedKt, ' kt'),
                          ),
                          FactRow(
                            label: l10n.aircraftTas,
                            value: _num(telemetry.trueAirspeedKt, ' kt'),
                          ),
                          FactRow(
                            label: l10n.aircraftVerticalSpeed,
                            value: _num(telemetry.verticalSpeedFpm, ' fpm'),
                          ),
                          _GroupTitle(l10n.aircraftGroupAttitude),
                          FactRow(
                            label: l10n.aircraftHeadingTrue,
                            value: _num(telemetry.headingDeg, '°'),
                          ),
                          FactRow(
                            label: l10n.aircraftHeadingMag,
                            value: _num(telemetry.headingMagDeg, '°'),
                          ),
                          FactRow(
                            label: l10n.aircraftPitch,
                            value: _num(telemetry.pitchDeg, '°'),
                          ),
                          FactRow(
                            label: l10n.aircraftRoll,
                            value: _num(telemetry.rollDeg, '°'),
                          ),
                          _GroupTitle(l10n.aircraftGroupAutopilot),
                          FactRow(
                            label: l10n.aircraftApOn,
                            value: telemetry.autopilotOn == null
                                ? '—'
                                : telemetry.autopilotOn!
                                ? l10n.aircraftApOnLabel
                                : l10n.aircraftApOffLabel,
                          ),
                          FactRow(
                            label: l10n.aircraftApAltitude,
                            value: _num(telemetry.apAltitudeFt, ' ft'),
                          ),
                          FactRow(
                            label: l10n.aircraftApHeading,
                            value: _num(telemetry.apHeadingDeg, '°'),
                          ),
                          FactRow(
                            label: l10n.aircraftApSpeed,
                            value: _num(telemetry.apSpeedKt, ' kt'),
                          ),
                          FactRow(
                            label: l10n.aircraftApVs,
                            value: _num(telemetry.apVerticalSpeedFpm, ' fpm'),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  static String _num(num? v, String unit) =>
      v == null ? '—' : '${v.toStringAsFixed(v.abs() < 100 ? 1 : 0)}$unit';

  static String _lat(double v) =>
      '${v.abs().toStringAsFixed(4)}° ${v >= 0 ? 'N' : 'S'}';

  static String _lon(double v) =>
      '${v.abs().toStringAsFixed(4)}° ${v >= 0 ? 'E' : 'W'}';
}

/// Connection state strip at the top of the panel.
class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.state, this.error});

  final SimConnectionState state;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final (label, color, icon) = switch (state) {
      SimConnectionState.connected => (
          l10n.simConnConnected,
          colors.success,
          Icons.check_circle_rounded,
        ),
      SimConnectionState.connecting => (
          l10n.simConnConnecting,
          colors.accent,
          Icons.pending_rounded,
        ),
      SimConnectionState.error => (
          l10n.simConnError,
          colors.danger,
          Icons.error_outline_rounded,
        ),
      _ => (
          l10n.simConnDisconnected,
          colors.textSecondary,
          Icons.link_off_rounded,
        ),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              error == null || state != SimConnectionState.error
                  ? label
                  : '$label — $error',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n, required this.colors});

  final AppLocalizations l10n;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flight_takeoff_rounded,
              size: 30,
              color: colors.textDisabled,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.aircraftNotConnected,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.aircraftNotConnectedHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.5,
                color: colors.textDisabled,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () => openSettingsTab(
                context,
                SettingsLanding.simulator,
              ),
              child: Text(l10n.aircraftOpenSettings),
            ),
          ],
        ),
      ),
    );
  }

}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 2),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: colors.accent,
        ),
      ),
    );
  }
}

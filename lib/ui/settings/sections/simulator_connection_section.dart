import 'package:flutter/material.dart';

import '../../../data/settings/settings_controller.dart';
import '../../../data/settings/simulator_install.dart';
import '../../../l10n/app_localizations.dart';
import '../../../sim/sim_connection_service.dart';
import '../../../sim/simulator_connector.dart';
import '../../theme/app_colors.dart';
import '../settings_page.dart';
import '../widgets/settings_text_field.dart';
import '../widgets/settings_tile.dart';

/// The "Simulator" settings category (top level, next to General): the
/// live X-Plane Web API link — connection state, connect/disconnect,
/// the Web API port and the auto-connect switch. Install management
/// lives under Data → Simulators; this section is about the LINK.
class SimulatorConnectionSection extends StatelessWidget {
  const SimulatorConnectionSection({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsSectionBody(
      title: l10n.settingsCategorySimulator,
      children: [
        ListenableBuilder(
          listenable: Listenable.merge([controller, SimConnectionService.instance]),
          builder: (context, _) => _buildStateCard(context, controller),
        ),
        const SizedBox(height: 22),
        SettingsSectionTitle(l10n.simConnStateTitle),
        SettingsCard(
          children: [
            SettingsTile(
              title: l10n.simWebApiPort,
              leading: const Icon(Icons.lan_outlined),
              trailing: SizedBox(
                width: 110,
                child: SettingsTextField(
                  initialValue: '${controller.value.xplaneWebApiPort}',
                  keyboardType: TextInputType.number,
                  onCommit: (v) {
                    final port = int.tryParse(v?.trim() ?? '') ?? 8086;
                    controller.setXplaneWebApiPort(
                      port.clamp(1, 65535),
                    );
                  },
                ),
              ),
            ),
            SettingsSwitchTile(
              title: l10n.simAutoConnectLabel,
              leading: const Icon(Icons.power_rounded),
              value: controller.value.simAutoConnect,
              onChanged: controller.setSimAutoConnect,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStateCard(
    BuildContext context,
    SettingsController controller,
  ) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final service = SimConnectionService.instance;
    final state = service.state;

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

    final xplaneInstall = controller.value.simulators
        .where((s) => s.type == SimulatorType.xplane12)
        .toList();

    return SettingsCard(
      children: [
        SettingsTile(
          title: label,
          subtitle: state == SimConnectionState.error
              ? service.error ?? ''
              : state == SimConnectionState.connected
              ? '${l10n.simConnVersion}: ${service.xplaneVersion ?? l10n.simConnUnknownVersion}'
              : null,
          leading: Icon(icon, color: color),
          trailing: xplaneInstall.isEmpty
              ? null
              : state == SimConnectionState.connected
              ? OutlinedButton(
                  onPressed: service.disconnect,
                  child: Text(l10n.simConnDisconnect),
                )
              : FilledButton(
                  onPressed: service.state == SimConnectionState.connecting
                      ? null
                      : () => service.connect(
                            xplaneInstall.first,
                            controller,
                          ),
                  child: Text(l10n.simConnConnect),
                ),
        ),
        SettingsTile(
          title: l10n.simConnAddress,
          leading: const Icon(Icons.dns_outlined),
          trailing: Text(
            '127.0.0.1:${controller.value.xplaneWebApiPort}',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
        ),
        if (xplaneInstall.isEmpty)
          SettingsTile(
            title: l10n.simConnNoInstall,
            leading: const Icon(Icons.info_outline_rounded),
          ),
      ],
    );
  }
}

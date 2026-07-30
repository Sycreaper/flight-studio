import 'package:flutter/material.dart';

import '../../../data/settings/settings_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/floating_dialog.dart';
import '../settings_page.dart';
import '../widgets/settings_text_field.dart';
import '../widgets/settings_tile.dart';

/// Simulator connections.
///
/// X-Plane 12 is the MVP target (per README), so its fields are fully
/// interactive. MSFS / Prepar3D ship later behind the C++ SimConnect bridge
/// daemon — rendered as a planned card rather than hidden.
class SimulatorSection extends StatelessWidget {
  const SimulatorSection({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = controller.value;
        return SettingsSectionBody(
          title: l10n.settingsSimulatorTitle,
          description: l10n.settingsSimulatorDesc,
          children: [
            SettingsSectionTitle(l10n.settingsXplaneTitle),
            SettingsCard(
              children: [
                SettingsTile(
                  title: l10n.settingsXplaneInstallPath,
                  subtitle: l10n.settingsXplaneInstallHint,
                  leading: const Icon(Icons.folder_open_rounded),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  trailing: SizedBox(
                    width: 320,
                    child: SettingsTextField(
                      initialValue: s.xplaneInstallPath,
                      placeholder: l10n.settingsNotSet,
                      onCommit: controller.setXplaneInstallPath,
                      suffix: const Icon(Icons.folder_rounded, size: 16),
                    ),
                  ),
                ),
                SettingsTile(
                  title: l10n.settingsXplaneUdpPort,
                  subtitle: l10n.settingsXplaneUdpPortHint,
                  leading: const Icon(Icons.input_rounded),
                  trailing: SizedBox(
                    width: 140,
                    child: SettingsTextField(
                      initialValue: s.xplaneUdpPort.toString(),
                      placeholder: '49000',
                      keyboardType: TextInputType.number,
                      onCommit: (v) => controller.setXplaneUdpPort(
                        int.tryParse(v ?? '') ?? 49000,
                      ),
                    ),
                  ),
                ),
                SettingsTile(
                  title: l10n.settingsXplaneBridgePort,
                  subtitle: l10n.settingsXplaneBridgePortHint,
                  leading: const Icon(Icons.settings_input_component_rounded),
                  trailing: SizedBox(
                    width: 140,
                    child: SettingsTextField(
                      initialValue: s.xplaneBridgePort.toString(),
                      placeholder: '49001',
                      keyboardType: TextInputType.number,
                      onCommit: (v) => controller.setXplaneBridgePort(
                        int.tryParse(v ?? '') ?? 49001,
                      ),
                    ),
                  ),
                ),
                SettingsTile(
                  title: l10n.settingsXplaneInstallBridge,
                  subtitle: l10n.settingsXplaneInstallBridgeHint,
                  leading: const Icon(Icons.download_for_offline_outlined),
                  trailing: OutlinedButton.icon(
                    icon: const Icon(Icons.file_download_outlined, size: 16),
                    label: Text(l10n.settingsXplaneInstallBridge),
                    onPressed: () => _showPlannedDialog(context, l10n),
                  ),
                ),
                SettingsTile(
                  title: l10n.settingsXplaneTestConnection,
                  subtitle: _connectionStatusLine(
                    l10n,
                    s.xplaneUdpPort,
                    configured:
                        s.xplaneInstallPath != null &&
                        s.xplaneInstallPath!.isNotEmpty,
                  ),
                  leading: const Icon(Icons.cable_rounded),
                  trailing: FilledButton.icon(
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: Text(l10n.settingsXplaneTestConnection),
                    onPressed: () => _showPlannedDialog(context, l10n),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SettingsSectionTitle(l10n.settingsMsfsTitle),
            SettingsCard(
              children: [
                SettingsTile(
                  title: l10n.settingsMsfsBridgePath,
                  subtitle: l10n.settingsMsfsBridgePathHint,
                  leading: const Icon(Icons.construction_rounded),
                  trailing: const SettingsBadge.planned(label: 'Planned'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
                  child: Text(
                    l10n.settingsMsfsPlanned,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _connectionStatusLine(
    AppLocalizations l10n,
    int port, {
    required bool configured,
  }) {
    if (!configured) return l10n.settingsXplaneStatusDisconnected;
    return l10n.settingsXplaneStatusConnected(port);
  }

  void _showPlannedDialog(BuildContext context, AppLocalizations l10n) {
    showFloatingDialog(
      context,
      title: l10n.comingSoon,
      width: 440,
      height: 240,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            l10n.settingsRestartHint,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
      ),
    );
  }
}

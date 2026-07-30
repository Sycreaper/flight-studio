import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/settings/settings_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../settings_page.dart';
import '../widgets/settings_text_field.dart';
import '../widgets/settings_tile.dart';

/// Embedded HTTP/WebSocket server for the companion phone and web clients.
///
/// All settings persist; the actual server boots up in a later phase. The
/// regenerate-token button is fully functional — it produces a fresh 32-byte
/// hex token in-process so the value is real even before the server ships.
class RemoteAccessSection extends StatelessWidget {
  const RemoteAccessSection({super.key, required this.controller});

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
          title: l10n.settingsRemoteTitle,
          description: l10n.settingsRemoteDesc,
          children: [
            SettingsSectionTitle(l10n.settingsRemoteStatusTitle),
            SettingsCard(
              children: [
                SettingsTile(
                  title: l10n.settingsRemoteEnable,
                  subtitle: l10n.settingsRemoteDesc,
                  leading: const Icon(Icons.dns_outlined),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  trailing: Switch(
                    value: s.remoteEnabled,
                    onChanged: controller.setRemoteEnabled,
                  ),
                ),
                SettingsTile(
                  title: l10n.settingsRemoteStatusTitle,
                  leading: const Icon(Icons.radio_button_checked_rounded),
                  trailing: s.remoteEnabled
                      ? SettingsBadge.connected(
                          label: l10n.settingsRemoteRunningOn(
                            '0.0.0.0',
                            s.remotePort,
                          ),
                        )
                      : SettingsBadge.disconnected(
                          label: l10n.settingsRemoteNotRunning,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SettingsSectionTitle(l10n.settingsRemotePort),
            SettingsCard(
              children: [
                SettingsTile(
                  title: l10n.settingsRemotePort,
                  subtitle: l10n.settingsRemotePortHint,
                  leading: const Icon(Icons.numbers_rounded),
                  trailing: SizedBox(
                    width: 140,
                    child: SettingsTextField(
                      initialValue: s.remotePort.toString(),
                      placeholder: '48080',
                      keyboardType: TextInputType.number,
                      onCommit: (v) => controller.setRemotePort(
                        int.tryParse(v ?? '') ?? 48080,
                      ),
                    ),
                  ),
                ),
                SettingsSwitchTile(
                  title: l10n.settingsRemoteMdns,
                  subtitle: l10n.settingsRemoteMdnsHint,
                  leading: const Icon(Icons.wifi_find_rounded),
                  value: s.remoteMdns,
                  onChanged: controller.setRemoteMdns,
                ),
              ],
            ),
            const SizedBox(height: 22),
            SettingsSectionTitle(l10n.settingsRemoteToken),
            SettingsCard(
              children: [
                SettingsTile(
                  title: l10n.settingsRemoteToken,
                  subtitle: l10n.settingsRemoteTokenHint,
                  leading: const Icon(Icons.vpn_key_outlined),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  trailing: SizedBox(
                    width: 320,
                    child: SettingsTextField(
                      initialValue: s.remoteToken.isEmpty
                          ? null
                          : s.remoteToken,
                      placeholder: l10n.settingsNotSet,
                      onCommit: (v) => controller.setRemoteToken(v ?? ''),
                    ),
                  ),
                ),
                SettingsTile(
                  title: l10n.settingsRemoteRegenerateToken,
                  subtitle: l10n.settingsRestartHint,
                  leading: const Icon(Icons.refresh_rounded),
                  trailing: OutlinedButton.icon(
                    icon: const Icon(Icons.autorenew_rounded, size: 16),
                    label: Text(l10n.settingsRemoteRegenerateToken),
                    onPressed: () => controller.setRemoteToken(_newToken()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.settingsRestartHint,
              style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
            ),
          ],
        );
      },
    );
  }

  /// Generates a fresh random 64-char hex token. Uses [math.Random.secure] so
  /// the result is suitable as a shared secret.
  static String _newToken() {
    final rng = math.Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

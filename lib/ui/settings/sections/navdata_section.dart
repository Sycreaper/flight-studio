import 'package:flutter/material.dart';

import '../../../data/settings/settings_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/floating_dialog.dart';
import '../settings_page.dart';
import '../widgets/settings_tile.dart';

/// Navigation data sources — bundled, Navigraph (BYO subscription) and SimBrief
/// (BYO account). The toggles persist immediately; the OAuth2 buttons surface
/// a planned-feature dialog since the auth flow ships in a later phase.
class NavDataSection extends StatelessWidget {
  const NavDataSection({super.key, required this.controller});

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
          title: l10n.settingsNavdataTitle,
          description: l10n.settingsNavdataDesc,
          children: [
            SettingsSectionTitle(l10n.settingsNavdataBundledTitle),
            SettingsCard(
              children: [
                SettingsSwitchTile(
                  title: l10n.settingsNavdataOurAirports,
                  subtitle: l10n.settingsNavdataOurAirportsHint,
                  leading: const Icon(Icons.flight_land_rounded),
                  value: s.useOurAirports,
                  onChanged: controller.setUseOurAirports,
                ),
                SettingsSwitchTile(
                  title: l10n.settingsNavdataFaaCifp,
                  subtitle: l10n.settingsNavdataFaaCifpHint,
                  leading: const Icon(Icons.assignment_outlined),
                  value: s.useFaaCifp,
                  onChanged: controller.setUseFaaCifp,
                ),
                SettingsSwitchTile(
                  title: l10n.settingsNavdataXplaneNative,
                  subtitle: l10n.settingsNavdataXplaneNativeHint,
                  leading: const Icon(Icons.memory_rounded),
                  value: s.useXplaneNative,
                  onChanged: controller.setUseXplaneNative,
                ),
                SettingsTile(
                  title: l10n.settingsNavdataRefreshBundled,
                  subtitle: l10n.settingsRestartHint,
                  leading: const Icon(Icons.sync_rounded),
                  trailing: OutlinedButton(
                    onPressed: () => _showPlannedDialog(context, l10n),
                    child: Text(l10n.settingsNavdataRefreshBundled),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SettingsSectionTitle(l10n.settingsNavdataNavigraphTitle),
            SettingsCard(
              children: [
                SettingsTile(
                  title: l10n.settingsNavdataNavigraphHint,
                  leading: const Icon(Icons.account_circle_outlined),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  trailing: s.navigraphSignedIn
                      ? SettingsBadge.connected(
                          label: l10n.settingsNavdataNavigraphSignedIn(
                            s.navigraphUser!,
                          ),
                        )
                      : const SettingsBadge.disconnected(
                          label: 'Not signed in',
                        ),
                ),
                SettingsTile(
                  title: l10n.settingsNavdataNavigraphAirac,
                  subtitle: l10n.settingsNavdataNavigraphHint,
                  leading: const Icon(Icons.event_available_rounded),
                  trailing: Text(
                    s.navigraphAirac ?? l10n.settingsNavdataNavigraphAiracNone,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: s.navigraphAirac == null
                          ? colors.textDisabled
                          : colors.textPrimary,
                    ),
                  ),
                ),
                SettingsTile(
                  title: s.navigraphSignedIn
                      ? l10n.settingsNavdataNavigraphSignOut
                      : l10n.settingsNavdataNavigraphSignIn,
                  leading: const Icon(Icons.login_rounded),
                  trailing: s.navigraphSignedIn
                      ? OutlinedButton(
                          onPressed: () => controller.setNavigraphUser(null),
                          child: Text(l10n.settingsNavdataNavigraphSignOut),
                        )
                      : FilledButton(
                          onPressed: () => _showPlannedDialog(context, l10n),
                          child: Text(l10n.settingsNavdataNavigraphSignIn),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SettingsSectionTitle(l10n.settingsNavdataSimBriefTitle),
            SettingsCard(
              children: [
                SettingsTile(
                  title: l10n.settingsNavdataSimBriefHint,
                  leading: const Icon(Icons.description_outlined),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  trailing: s.simbriefLinked
                      ? SettingsBadge.connected(
                          label: l10n.settingsNavdataSimBriefLinked(
                            s.simbriefUsername!,
                          ),
                        )
                      : const SettingsBadge.disconnected(label: 'Not linked'),
                ),
                SettingsTile(
                  title: s.simbriefLinked
                      ? l10n.settingsNavdataSimBriefUnlink
                      : l10n.settingsNavdataSimBriefLink,
                  leading: const Icon(Icons.link_rounded),
                  trailing: s.simbriefLinked
                      ? OutlinedButton(
                          onPressed: () => controller.setSimBriefUsername(null),
                          child: Text(l10n.settingsNavdataSimBriefUnlink),
                        )
                      : FilledButton(
                          onPressed: () => _showPlannedDialog(context, l10n),
                          child: Text(l10n.settingsNavdataSimBriefLink),
                        ),
                ),
              ],
            ),
          ],
        );
      },
    );
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

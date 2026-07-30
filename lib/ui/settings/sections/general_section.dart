import 'package:flutter/material.dart';

import '../../../data/settings/settings_controller.dart';
import '../../../data/settings/settings_enums.dart';
import '../../../l10n/app_localizations.dart';
import '../settings_page.dart';
import '../widgets/settings_tile.dart';

/// General preferences — appearance, language, startup, default units.
///
/// These are the only settings that affect the entire app immediately; other
/// sections only take effect once their feature ships.
class GeneralSection extends StatelessWidget {
  const GeneralSection({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = controller.value;
        return SettingsSectionBody(
          title: l10n.settingsCategoryGeneral,
          description: l10n.settingsCategoryGeneralDesc,
          children: [
            SettingsSectionTitle(l10n.settingsAppearanceTitle),
            SettingsCard(
              children: [
                SettingsTile(
                  title: l10n.settingsTheme,
                  subtitle: l10n.settingsThemeHint,
                  leading: const Icon(Icons.dark_mode_outlined),
                  trailing: SettingsSegmentedControl<ThemeMode>(
                    value: s.themeMode,
                    onChanged: controller.setThemeMode,
                    items: [
                      SettingsSegment(
                        value: ThemeMode.dark,
                        label: l10n.settingsThemeDark,
                      ),
                      SettingsSegment(
                        value: ThemeMode.light,
                        label: l10n.settingsThemeLight,
                      ),
                      SettingsSegment(
                        value: ThemeMode.system,
                        label: l10n.settingsThemeSystem,
                      ),
                    ],
                  ),
                ),
                SettingsTile(
                  title: l10n.settingsLanguage,
                  subtitle: l10n.settingsLanguageHint,
                  leading: const Icon(Icons.translate_rounded),
                  trailing: SettingsSegmentedControl<AppLocaleCode>(
                    value: s.localeCode,
                    onChanged: controller.setLocaleCode,
                    items: [
                      SettingsSegment(
                        value: AppLocaleCode.en,
                        label: l10n.settingsLanguageEn,
                      ),
                      SettingsSegment(
                        value: AppLocaleCode.zh,
                        label: l10n.settingsLanguageZh,
                      ),
                      SettingsSegment(
                        value: AppLocaleCode.system,
                        label: l10n.settingsThemeSystem,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SettingsSectionTitle(l10n.settingsStartupTitle),
            SettingsCard(
              children: [
                SettingsSwitchTile(
                  title: l10n.settingsReopenLastWorkspace,
                  subtitle: l10n.settingsReopenLastWorkspaceHint,
                  leading: const Icon(Icons.history_rounded),
                  value: s.reopenLastWorkspace,
                  onChanged: controller.setReopenLastWorkspace,
                ),
                SettingsSwitchTile(
                  title: l10n.settingsCheckUpdatesOnLaunch,
                  subtitle: l10n.settingsCheckUpdatesOnLaunchHint,
                  leading: const Icon(Icons.system_update_alt_rounded),
                  value: s.checkUpdatesOnLaunch,
                  onChanged: controller.setCheckUpdatesOnLaunch,
                ),
              ],
            ),
            const SizedBox(height: 22),
            SettingsSectionTitle(l10n.settingsUnitsTitle),
            SettingsCard(
              children: [
                SettingsTile(
                  title: l10n.settingsUnitsTitle,
                  subtitle: l10n.settingsUnitsHint,
                  leading: const Icon(Icons.straighten_rounded),
                  trailing: SettingsSegmentedControl<bool>(
                    value: s.preferMetric,
                    onChanged: controller.setPreferMetric,
                    items: [
                      SettingsSegment(
                        value: true,
                        label: l10n.settingsUnitsMetric,
                      ),
                      SettingsSegment(
                        value: false,
                        label: l10n.settingsUnitsImperial,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

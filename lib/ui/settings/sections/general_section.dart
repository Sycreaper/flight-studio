import 'package:flutter/material.dart';

import '../../../data/settings/settings_controller.dart';
import '../../../data/settings/settings_enums.dart';
import '../../../data/system/font_service.dart';
import '../../../l10n/app_localizations.dart';
import '../settings_page.dart';
import '../widgets/settings_dropdown.dart';
import '../widgets/settings_tile.dart';

/// General preferences — appearance, language, font, startup, default units.
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  trailing: SettingsDropdown<AppLocaleCode>(
                    value: s.localeCode,
                    onChanged: controller.setLocaleCode,
                    items: [
                      SettingsDropdownItem(
                        value: AppLocaleCode.system,
                        label: l10n.languageSystem,
                      ),
                      SettingsDropdownItem(
                        value: AppLocaleCode.en,
                        label: l10n.settingsLanguageEn,
                      ),
                      SettingsDropdownItem(
                        value: AppLocaleCode.zh,
                        label: l10n.settingsLanguageZh,
                      ),
                    ],
                  ),
                ),
                _FontTile(controller: controller),
              ],
            ),
            const SizedBox(height: 22),
            SettingsSectionTitle(l10n.settingsStartupTitle),
            SettingsCard(
              children: [
                SettingsSwitchTile(
                  title: l10n.settingsSplash,
                  subtitle: l10n.settingsSplashHint,
                  leading: const Icon(Icons.wb_sunny_outlined),
                  value: s.splashEnabled,
                  onChanged: controller.setSplashEnabled,
                ),
                SettingsTile(
                  title: l10n.settingsSplashScan,
                  subtitle: l10n.settingsSplashScanHint,
                  leading: const Icon(Icons.radar_rounded),
                  crossAxisAlignment: CrossAxisAlignment.center,
                  trailing: SettingsDropdown<SplashScanMode>(
                    value: s.splashScanMode,
                    onChanged: controller.setSplashScanMode,
                    items: [
                      SettingsDropdownItem(
                        value: SplashScanMode.always,
                        label: l10n.splashScanAlways,
                      ),
                      SettingsDropdownItem(
                        value: SplashScanMode.after14Days,
                        label: l10n.splashScanAfter14,
                      ),
                      SettingsDropdownItem(
                        value: SplashScanMode.after28Days,
                        label: l10n.splashScanAfter28,
                      ),
                      SettingsDropdownItem(
                        value: SplashScanMode.never,
                        label: l10n.splashScanNever,
                      ),
                    ],
                  ),
                ),
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
                          value: true, label: l10n.settingsUnitsMetric),
                      SettingsSegment(
                          value: false, label: l10n.settingsUnitsImperial),
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

/// Interface-font picker. Lists every font family installed on the machine
/// (no search — plain scrollable popup, per spec) plus a “Default” entry
/// that restores the platform font. Long lists scroll inside the popup.
class _FontTile extends StatefulWidget {
  const _FontTile({required this.controller});

  final SettingsController controller;

  @override
  State<_FontTile> createState() => _FontTileState();
}

class _FontTileState extends State<_FontTile> {
  List<String>? _fonts;

  @override
  void initState() {
    super.initState();
    FontService.instance.installedFonts().then((f) {
      if (mounted) setState(() => _fonts = f);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fonts = _fonts;
    return SettingsTile(
      title: l10n.settingsFontFamily,
      subtitle: l10n.settingsFontFamilyHint,
      leading: const Icon(Icons.font_download_outlined),
      crossAxisAlignment: CrossAxisAlignment.center,
      trailing: fonts == null
          ? const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : SettingsDropdown<String>(
        value: widget.controller.value.fontFamily ?? '',
        width: 200,
        onChanged: (v) =>
            widget.controller.setFontFamily(v.isEmpty ? null : v),
        items: [
          SettingsDropdownItem(
            value: '',
            label: l10n.settingsFontDefault,
          ),
          for (final f in fonts) SettingsDropdownItem(value: f, label: f),
        ],
      ),
    );
  }
}

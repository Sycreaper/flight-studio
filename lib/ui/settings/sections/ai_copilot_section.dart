import 'package:flutter/material.dart';

import '../../../data/settings/settings_controller.dart';
import '../../../data/settings/settings_enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../settings_page.dart';
import '../settings_window.dart';
import '../widgets/settings_text_field.dart';
import '../widgets/settings_tile.dart';

/// AI Copilot (BYOK) configuration.
///
/// The API key itself is managed centrally in the **API Keys** settings
/// section — this section only configures which provider / endpoint / model
/// the key is for, plus the tool-policy toggles.
class AiCopilotSection extends StatelessWidget {
  const AiCopilotSection({super.key, required this.controller});

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
          title: l10n.settingsAiTitle,
          description: l10n.settingsAiDesc,
          children: [
            SettingsSectionTitle(l10n.settingsAiProvider),
            SettingsCard(
              children: [
                SettingsTile(
                  title: l10n.settingsAiProvider,
                  subtitle: l10n.settingsAiProviderHint,
                  leading: const Icon(Icons.cloud_outlined),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  trailing: SettingsSegmentedControl<AiProvider>(
                    value: s.aiProvider,
                    onChanged: controller.setAiProvider,
                    items: [
                      SettingsSegment(
                        value: AiProvider.openAi,
                        label: l10n.settingsAiProviderOpenAi,
                      ),
                      SettingsSegment(
                        value: AiProvider.anthropic,
                        label: l10n.settingsAiProviderAnthropic,
                      ),
                      SettingsSegment(
                        value: AiProvider.ollama,
                        label: l10n.settingsAiProviderOllama,
                      ),
                    ],
                  ),
                ),
                SettingsTile(
                  title: l10n.settingsAiApiKey,
                  subtitle: s.aiConfigured
                      ? l10n.settingsAiApiKeyHidden
                      : l10n.settingsAiApiKeyHint,
                  leading: const Icon(Icons.key_rounded),
                  trailing: s.aiConfigured
                      ? SettingsBadge.connected(label: l10n.apiKeySet)
                      : const SettingsBadge.disconnected(label: '—'),
                  onTap: () =>
                      openSettingsTab(context, SettingsLanding.apiKeys),
                ),
                SettingsTile(
                  title: l10n.settingsAiEndpoint,
                  subtitle: l10n.settingsAiEndpointHint,
                  leading: const Icon(Icons.link_rounded),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  trailing: SizedBox(
                    width: 320,
                    child: SettingsTextField(
                      initialValue: s.aiEndpoint,
                      placeholder: l10n.settingsAiEndpointPlaceholder,
                      keyboardType: TextInputType.url,
                      onCommit: controller.setAiEndpoint,
                    ),
                  ),
                ),
                SettingsTile(
                  title: l10n.settingsAiModel,
                  subtitle: l10n.settingsAiModelHint,
                  leading: const Icon(Icons.memory_rounded),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  trailing: SizedBox(
                    width: 220,
                    child: SettingsTextField(
                      initialValue: s.aiModel,
                      placeholder: l10n.settingsAiModelPlaceholder,
                      onCommit: controller.setAiModel,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SettingsSectionTitle(l10n.settingsAiToolPolicy),
            SettingsCard(
              children: [
                SettingsSwitchTile(
                  title: l10n.settingsAiConfirmWrites,
                  subtitle: l10n.settingsAiConfirmWritesHint,
                  leading: const Icon(Icons.verified_user_outlined),
                  value: s.aiConfirmWrites,
                  onChanged: controller.setAiConfirmWrites,
                ),
                SettingsSwitchTile(
                  title: l10n.settingsAiAutoRead,
                  subtitle: l10n.settingsAiAutoReadHint,
                  leading: const Icon(Icons.menu_book_outlined),
                  value: s.aiAutoRead,
                  onChanged: controller.setAiAutoRead,
                ),
              ],
            ),
            if (s.aiConfigured)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 14, color: colors.success),
                    const SizedBox(width: 6),
                    Text(
                      l10n.apiKeySet,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

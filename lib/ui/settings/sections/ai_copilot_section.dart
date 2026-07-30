import 'package:flutter/material.dart';

import '../../../data/settings/settings_controller.dart';
import '../../../data/settings/settings_enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../settings_page.dart';
import '../widgets/settings_text_field.dart';
import '../widgets/settings_tile.dart';

/// AI Copilot (BYOK) configuration.
///
/// Every field is fully interactive and persists locally. The actual LLM
/// transport and MCP tool registry ship in later phases — these values are the
/// inputs those phases will read.
class AiCopilotSection extends StatefulWidget {
  const AiCopilotSection({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<AiCopilotSection> createState() => _AiCopilotSectionState();
}

class _AiCopilotSectionState extends State<AiCopilotSection> {
  bool _obscureKey = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final s = widget.controller.value;
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
                    onChanged: widget.controller.setAiProvider,
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
                  subtitle: l10n.settingsAiApiKeyHint,
                  leading: const Icon(Icons.key_rounded),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  trailing: SizedBox(
                    width: 320,
                    child: _ApiKeyField(
                      controller: widget.controller,
                      obscure: _obscureKey,
                      onToggleObscure: () =>
                          setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
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
                      onCommit: widget.controller.setAiEndpoint,
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
                      onCommit: widget.controller.setAiModel,
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
                  onChanged: widget.controller.setAiConfirmWrites,
                ),
                SettingsSwitchTile(
                  title: l10n.settingsAiAutoRead,
                  subtitle: l10n.settingsAiAutoReadHint,
                  leading: const Icon(Icons.menu_book_outlined),
                  value: s.aiAutoRead,
                  onChanged: widget.controller.setAiAutoRead,
                ),
              ],
            ),
            if (s.aiConfigured)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: colors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.settingsAiProvider,
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

class _ApiKeyField extends StatelessWidget {
  const _ApiKeyField({
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
  });

  final SettingsController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = controller.value;
    return SettingsTextField(
      initialValue: s.aiApiKey,
      placeholder: l10n.settingsAiApiKeyHidden,
      obscure: obscure,
      onCommit: controller.setAiApiKey,
      suffix: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (s.aiApiKey != null && s.aiApiKey!.isNotEmpty)
            IconButton(
              tooltip: l10n.settingsAiClearApiKey,
              icon: const Icon(Icons.close_rounded, size: 14),
              visualDensity: VisualDensity.compact,
              onPressed: () => controller.setAiApiKey(null),
            ),
          IconButton(
            tooltip: obscure
                ? MaterialLocalizations.of(context).showAccountsLabel
                : MaterialLocalizations.of(context).hideAccountsLabel,
            icon: Icon(
              obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 16,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: onToggleObscure,
          ),
        ],
      ),
    );
  }
}

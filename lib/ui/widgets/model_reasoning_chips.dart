import 'package:flutter/material.dart';

import '../../data/settings/api_key_entry.dart';
import '../../data/settings/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../chat/chat_session.dart';
import '../settings/settings_window.dart';
import '../theme/app_colors.dart';

/// Model + reasoning-effort chips shared by the welcome Start page and the
/// chat tab. Both surfaces render the exact same selection (owned by
/// [ChatSession]) driven by the exact same option list (the app's
/// OpenAI-compatible API keys), so they can never drift apart.
///
/// The model menu groups models **per API key entry** — the user's stored
/// keys are the source of truth, not a hardcoded catalog.
class ModelReasoningChips extends StatelessWidget {
  const ModelReasoningChips({super.key, this.settings});

  final SettingsController? settings;

  @override
  Widget build(BuildContext context) {
    // Detached controller when no AppScope is mounted (tests) — the chips
    // render empty rather than crashing.
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    final effectiveSettings =
        settings ?? scope?.settings ?? SettingsController();
    // Restore the persisted model selection once the key list is available.
    ChatSession.instance.restoreSelection(effectiveSettings.value.apiKeys);
    return ListenableBuilder(
      listenable: Listenable.merge([effectiveSettings, ChatSession.instance]),
      builder: (context, _) {
        final groups = _groupByKey(effectiveSettings);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModelMenu(
              groups: groups,
              onChanged: (key) => ChatSession.instance.selectKey(key),
            ),
            const SizedBox(width: 8),
            const _ReasoningMenu(),
          ],
        );
      },
    );
  }

  /// One menu group per openAiCompatible API key entry. The group title is
  /// the key's label (or the provider display name); its option shows the
  /// model that will actually be used (entry model or provider default).
  List<({String title, ApiKeyEntry key, String model, String subtitle})>
  _groupByKey(SettingsController settings) {
    final l10nless =
        <({String title, ApiKeyEntry key, String model, String subtitle})>[];
    for (final entry in settings.value.apiKeys) {
      if (entry.type != ApiKeyType.openAiCompatible) continue;
      final model = entry.model?.trim().isNotEmpty == true
          ? entry.model!.trim()
          : switch (entry.provider) {
              'glm' => 'glm-4-flash',
              'qwen' => 'qwen-turbo',
              'deepseek' => 'deepseek-chat',
              _ => '',
            };
      l10nless.add((
        title: entry.label?.isNotEmpty == true
            ? entry.label!
            : _providerName(entry.provider),
        key: entry,
        model: model,
        subtitle: _providerName(entry.provider),
      ));
    }
    return l10nless;
  }

  static String _providerName(String? provider) => switch (provider) {
    'glm' => 'GLM',
    'qwen' => l10nProviderQwenFallback,
    'deepseek' => 'DeepSeek',
    _ => 'Custom',
  };
}

// Provider display names that l10n doesn't need to translate (brand names).
const l10nProviderQwenFallback = 'Qwen';

class _ModelMenu extends StatelessWidget {
  const _ModelMenu({required this.groups, required this.onChanged});

  final List<({String title, ApiKeyEntry key, String model, String subtitle})>
  groups;
  final ValueChanged<ApiKeyEntry> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final session = ChatSession.instance;
    final selectedId = session.selectedKey?.id;
    final selectedGroup = groups
        .where((g) => g.key.id == selectedId)
        .firstOrNull;
    final label = selectedGroup != null
        ? '${selectedGroup.subtitle} · ${session.selectedModel ?? selectedGroup.model}'
        : l10n.modelChipLabel;

    return PopupMenuButton<String>(
      onSelected: (id) {
        final group = groups.where((g) => g.key.id == id).firstOrNull;
        if (group != null) onChanged(group.key);
      },
      color: colors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.border),
      ),
      elevation: 8,
      padding: EdgeInsets.zero,
      menuPadding: const EdgeInsets.symmetric(vertical: 4),
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        if (groups.isEmpty)
          PopupMenuItem(
            enabled: false,
            height: 40,
            child: Text(
              l10n.openAiModelsEmpty,
              style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
            ),
          )
        else
          for (final group in groups) ...[
            PopupMenuItem(
              enabled: false,
              height: 26,
              child: Text(
                group.title.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: colors.textDisabled,
                ),
              ),
            ),
            PopupMenuItem(
              value: group.key.id,
              height: 38,
              child: Row(
                children: [
                  if (group.key.id == selectedId)
                    Icon(Icons.check_rounded, size: 14, color: colors.accent)
                  else
                    const SizedBox(width: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      group.model.isEmpty
                          ? l10n.modelChipNoModel
                          : '${group.subtitle} · ${group.model}',
                      style: TextStyle(fontSize: 12, color: colors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.memory_rounded, size: 12, color: colors.accent),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 15,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasoningMenu extends StatelessWidget {
  const _ReasoningMenu();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final session = ChatSession.instance;

    String levelLabel(String value) => switch (value) {
      'none' => l10n.reasoningNone,
      'minimal' => l10n.reasoningMinimal,
      'low' => l10n.reasoningLow,
      'medium' => l10n.reasoningMedium,
      'high' => l10n.reasoningHigh,
      _ => l10n.reasoningXhigh,
    };

    const levels = ['none', 'minimal', 'low', 'medium', 'high', 'xhigh'];

    return PopupMenuButton<String>(
      onSelected: (v) => session.reasoningEffort = v,
      color: colors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.border),
      ),
      elevation: 8,
      padding: EdgeInsets.zero,
      menuPadding: const EdgeInsets.symmetric(vertical: 4),
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final level in levels)
          PopupMenuItem(
            value: level,
            height: 34,
            child: Row(
              children: [
                if (level == session.reasoningEffort)
                  Icon(Icons.check_rounded, size: 14, color: colors.accent)
                else
                  const SizedBox(width: 14),
                const SizedBox(width: 4),
                Text(
                  levelLabel(level),
                  style: TextStyle(fontSize: 12, color: colors.textPrimary),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology_outlined, size: 12, color: colors.accent),
            const SizedBox(width: 5),
            Text(
              levelLabel(session.reasoningEffort),
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 15,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

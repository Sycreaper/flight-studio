import 'package:flutter/material.dart';

import '../../data/settings/api_key_entry.dart';
import '../../data/settings/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../chat/chat_session.dart';
import '../settings/settings_window.dart';
import '../theme/app_colors.dart';

/// Model + reasoning-effort chips shared by every chat surface (welcome
/// page, chat tab, future drawers). Both chips render the exact selection
/// owned by [ChatSessionManager]; the model menu groups **per API key
/// entry** and
/// lists the models discovered from that endpoint when the key was created.
///
/// Layout contract: place directly below the prompt box inside the SAME
/// width constraint as the box, so the chips align with the box's left
/// edge (not the page's).
class ModelReasoningChips extends StatelessWidget {
  const ModelReasoningChips({super.key, this.settings});

  final SettingsController? settings;

  @override
  Widget build(BuildContext context) {
    // Detached controller when no AppScope is mounted (tests) — the chips
    // render empty rather than crashing.
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    final effectiveSettings = settings ?? scope?.settings ??
        SettingsController();
    // Restore the persisted model selection once the key list is available.
    ChatSessionManager.instance.restoreSelection(effectiveSettings.value.apiKeys);
    return ListenableBuilder(
      listenable: Listenable.merge([effectiveSettings, ChatSessionManager.instance]),
      builder: (context, _) {
        final groups = _groups(effectiveSettings);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModelMenu(groups: groups),
            const SizedBox(width: 8),
            // NOT const: the chip label must rebuild when the selection
            // changes (a const instance would be skipped by the framework).
            _ReasoningMenu(),
          ],
        );
      },
    );
  }

  /// One menu group per openAiCompatible API key entry; its options are the
  /// models discovered from that endpoint.
  List<({String title, ApiKeyEntry key})> _groups(
      SettingsController settings,) {
    return [
      for (final entry in settings.value.apiKeys)
        if (entry.type == ApiKeyType.openAiCompatible)
          (
          title: entry.label?.isNotEmpty == true
              ? entry.label!
              : _providerName(entry.provider),
          key: entry,
          ),
    ];
  }

  static String _providerName(String? provider) => switch (provider) {
    'glm' => 'GLM',
    'qwen' => 'Qwen',
    'deepseek' => 'DeepSeek',
    'minimax' => 'MiniMax',
    'moonshot' => 'Moonshot',
    'siliconflow' => 'SiliconFlow',
    'openrouter' => 'OpenRouter',
    _ => 'Custom',
  };
}

/// A chip with the tab-title hover treatment: transparent at rest, soft
/// raised surface + dark shadow on hover (120ms). Visual only — the
/// surrounding PopupMenuButton owns the tap gesture.
class _HoverChip extends StatefulWidget {
  const _HoverChip({required this.child});

  final Widget child;

  @override
  State<_HoverChip> createState() => _HoverChipState();
}

class _HoverChipState extends State<_HoverChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _hovering
              ? colors.surfaceRaised.withValues(alpha: 0.7)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: _hovering
              ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ]
              : const <BoxShadow>[],
        ),
        child: widget.child,
      ),
    );
  }
}

class _ModelMenu extends StatelessWidget {
  const _ModelMenu({required this.groups});

  final List<({String title, ApiKeyEntry key})> groups;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final session = ChatSessionManager.instance;
    final selectedId = session.selectedKey?.id;
    final label = session.selectedModelId ?? l10n.modelChipLabel;

    return PopupMenuButton<String>(
      onSelected: (value) {
        final sep = value.indexOf('\u0000');
        final keyId = value.substring(0, sep);
        final model = value.substring(sep + 1);
        final group = groups
            .where((g) => g.key.id == keyId)
            .firstOrNull;
        if (group != null) {
          ChatSessionManager.instance.selectKey(group.key, modelId: model);
        }
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
      constraints: const BoxConstraints(maxWidth: 340, maxHeight: 420),
      itemBuilder: (context) {
        if (groups.isEmpty) {
          return [
            PopupMenuItem(
              enabled: false,
              height: 40,
              child: Text(
                l10n.openAiModelsEmpty,
                style:
                TextStyle(fontSize: 11.5, color: colors.textSecondary),
              ),
            ),
          ];
        }
        return [
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
            if (group.key.models.isEmpty)
              PopupMenuItem(
                enabled: false,
                height: 34,
                child: Text(
                  l10n.modelChipNoModels,
                  style: TextStyle(
                      fontSize: 11.5, color: colors.textDisabled),
                ),
              )
            else
              for (final model in group.key.models)
                PopupMenuItem(
                  value: '${group.key.id}\u0000$model',
                  height: 34,
                  child: Row(
                    children: [
                      if (selectedId == group.key.id &&
                          session.selectedModelId == model)
                        Icon(Icons.check_rounded,
                            size: 14, color: colors.accent)
                      else
                        const SizedBox(width: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          model,
                          style: TextStyle(
                              fontSize: 12, color: colors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ];
      },
      child: _HoverChip(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.memory_rounded, size: 12, color: colors.accent),
            const SizedBox(width: 5),
            Text(label,
                style:
                TextStyle(fontSize: 11, color: colors.textSecondary)),
            Icon(Icons.arrow_drop_down_rounded,
                size: 15, color: colors.textSecondary),
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
    final session = ChatSessionManager.instance;

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
                Text(levelLabel(level),
                    style:
                    TextStyle(fontSize: 12, color: colors.textPrimary)),
              ],
            ),
          ),
      ],
      child: _HoverChip(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology_outlined, size: 12, color: colors.accent),
            const SizedBox(width: 5),
            Text(levelLabel(session.reasoningEffort),
                style:
                TextStyle(fontSize: 11, color: colors.textSecondary)),
            Icon(Icons.arrow_drop_down_rounded,
                size: 15, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

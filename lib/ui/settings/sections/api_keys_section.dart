import 'package:flutter/material.dart';

import '../../../data/settings/api_key_entry.dart';
import '../../../data/settings/settings_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/floating_window.dart';
import '../settings_page.dart';
import 'add_api_key_dialog.dart';

/// Unified API-key management section — a **dynamic list** of stored
/// credentials. The user can add unlimited keys of any type via the "+"
/// button, and delete individual entries.
///
/// **Layout:** green security banner at top, then a scrollable list of key
/// entries. Each entry shows the type icon, type label, masked key value
/// (first4…last4), optional user label, and a delete button. An empty-state
/// CTA is shown when no keys are stored.
///
/// Adding a key opens a [FloatingWindow]-style dialog ([AddApiKeyDialog]) with
/// a type dropdown and a password input field.
class ApiKeysSection extends StatelessWidget {
  const ApiKeysSection({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final keys = controller.value.apiKeys;
        return SettingsSectionBody(
          title: l10n.settingsCategoryApiKeys,
          description: l10n.settingsCategoryApiKeysDesc,
          children: [
            // Security note banner.
            _SecurityBanner(colors: colors, l10n: l10n),
            const SizedBox(height: 18),

            // List header with + button.
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.settingsCategoryApiKeys} (${keys.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => showAddApiKeyDialog(context, controller),
                  icon: Icon(Icons.add_rounded, size: 20, color: colors.accent),
                  tooltip: l10n.apiKeyAdd,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Key list or empty state.
            if (keys.isEmpty)
              _EmptyState(colors: colors, l10n: l10n)
            else
              ...keys.map(
                (entry) => _ApiKeyListTile(
                  entry: entry,
                  onDelete: () => controller.removeApiKey(entry.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SecurityBanner extends StatelessWidget {
  const _SecurityBanner({required this.colors, required this.l10n});

  final AppColors colors;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_rounded, size: 16, color: colors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.apiKeysSecurityNote,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colors, required this.l10n});

  final AppColors colors;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.vpn_key_outlined, size: 36, color: colors.textDisabled),
            const SizedBox(height: 12),
            Text(
              l10n.apiKeyEmpty,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.apiKeyEmptyHint,
              style: TextStyle(fontSize: 12, color: colors.accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiKeyListTile extends StatefulWidget {
  const _ApiKeyListTile({required this.entry, required this.onDelete});

  final ApiKeyEntry entry;
  final VoidCallback onDelete;

  @override
  State<_ApiKeyListTile> createState() => _ApiKeyListTileState();
}

class _ApiKeyListTileState extends State<_ApiKeyListTile> {
  bool _hovering = false;

  void _confirmDelete(
    BuildContext context,
    ApiKeyEntry entry,
    VoidCallback onConfirm,
  ) {
    final l10n = AppLocalizations.of(context)!;
    late OverlayEntry confirmEntry;
    confirmEntry = OverlayEntry(
      builder: (ctx) => FloatingWindow(
        title: l10n.apiKeyConfirmDelete,
        titleIcon: Icons.warning_amber_rounded,
        width: 400,
        height: 200,
        onClose: () => confirmEntry.remove(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 32,
                color: Theme.of(ctx).extension<AppColors>()!.danger,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.apiKeyConfirmDeleteDesc,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(ctx).extension<AppColors>()!.textSecondary,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => confirmEntry.remove(),
                    child: Text(l10n.settingsCancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(
                        ctx,
                      ).extension<AppColors>()!.danger,
                    ),
                    onPressed: () {
                      confirmEntry.remove();
                      onConfirm();
                    },
                    child: Text(l10n.apiKeyConfirmDelete.split('?')[0]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    Overlay.of(context).insert(confirmEntry);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _hovering
              ? colors.surfaceLowered.withValues(alpha: 0.5)
              : colors.surfaceRaised,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            // Floating welcome-card style — same as the navdata source
            // cards: no hard border, soft shadow.
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              _typeIcon(widget.entry.type),
              size: 18,
              color: colors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _typeLabel(widget.entry.type, l10n),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      // Provider chip — OpenAI-compatible entries carry the
                      // named provider (GLM / Qwen / … / 自定义).
                      if (widget.entry.type == ApiKeyType.openAiCompatible &&
                          widget.entry.provider != null &&
                          widget.entry.provider!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceLowered,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _providerLabel(widget.entry.provider!, l10n),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                      if (widget.entry.label != null &&
                          widget.entry.label!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '· ${widget.entry.label}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.lock_rounded, size: 11, color: colors.success),
                      const SizedBox(width: 4),
                      Text(
                        widget.entry.masked,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () =>
                  _confirmDelete(context, widget.entry, widget.onDelete),
              icon: Icon(Icons.close_rounded, size: 16),
              tooltip: l10n.settingsAiClearApiKey,
              color: _hovering ? colors.danger : colors.textDisabled,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
          ],
        ),
      ),
    );
  }

  /// Localized named-provider label — same mapping as the add-key dialog.
  static String _providerLabel(String persistedName, AppLocalizations l10n) {
    final provider = OpenAiProviderX.fromPersistedName(persistedName);
    return switch (provider) {
      OpenAiProvider.glm => l10n.openAiProviderGlm,
      OpenAiProvider.qwen => l10n.openAiProviderQwen,
      OpenAiProvider.deepseek => l10n.openAiProviderDeepseek,
      OpenAiProvider.minimax => l10n.openAiProviderMinimax,
      OpenAiProvider.moonshot => l10n.openAiProviderMoonshot,
      OpenAiProvider.siliconflow => l10n.openAiProviderSiliconflow,
      OpenAiProvider.openrouter => l10n.openAiProviderOpenrouter,
      OpenAiProvider.custom => l10n.openAiProviderCustom,
    };
  }

  static IconData _typeIcon(ApiKeyType type) {
    switch (type) {
      case ApiKeyType.osmToken:
        return Icons.terrain_rounded;
      case ApiKeyType.mapboxToken:
        return Icons.map_rounded;
      case ApiKeyType.openAiCompatible:
        return Icons.bolt_rounded;
      case ApiKeyType.flightAware:
        return Icons.flight_rounded;
      case ApiKeyType.customTileUrl:
        return Icons.link_rounded;
    }
  }

  static String _typeLabel(ApiKeyType type, AppLocalizations l10n) {
    switch (type) {
      case ApiKeyType.osmToken:
        return l10n.apiKeyTypeOsmToken;
      case ApiKeyType.mapboxToken:
        return l10n.apiKeyTypeMapboxToken;
      case ApiKeyType.openAiCompatible:
        return l10n.apiKeyTypeOpenAiCompatible;
      case ApiKeyType.flightAware:
        return l10n.apiKeyTypeFlightAware;
      case ApiKeyType.customTileUrl:
        return l10n.apiKeyTypeCustomTileUrl;
    }
  }
}

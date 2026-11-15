import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../mcp/tool_display.dart';
import '../chat/chat_session.dart';
import '../theme/app_colors.dart';

/// Embedded permission card shown when the copilot requests approval for
/// a tool call — the official `canUseTool` bridge surfaces these through
/// the gateway.
///
/// Style: gray (the default input-box colour, `surfaceLowered`) with a
/// floating shadow, as wide as the reply text area — no fixed width.
class ApprovalCard extends StatelessWidget {
  const ApprovalCard({
    super.key,
    required this.approval,
    required this.onAnswer,
  });

  final PendingApproval approval;

  /// `true` = allow, `false` = deny.
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Readable, localized tool name + value-only key-parameter marker
    // (e.g. `ZSPD`) — raw function names and `key: value` pairs never
    // surface in the title row.
    final displayName = toolDisplayName(approval.tool, l10n);
    final keyParams = toolKeyParams(approval.tool, approval.input);
    // The preview box stays only when the marker does not already show
    // every parameter.
    final previewRedundant =
        keyParamsCoverInput(approval.tool, approval.input);
    final inputPreview = approval.input.entries
        .take(4)
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: colors.surfaceLowered,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.10),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 16, color: colors.accent),
              const SizedBox(width: 8),
              Text(
                l10n.approvalTitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Title row: readable tool name, key-parameter values as a
          // marker chip to its right (value-only, e.g. `ZSPD`).
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.approvalWantsToUse(displayName),
                style: TextStyle(fontSize: 12.5, color: colors.textPrimary),
              ),
              if (keyParams.isNotEmpty) ...[
                const SizedBox(width: 6),
                _ParamChip(params: keyParams),
              ],
            ],
          ),
          if (inputPreview.isNotEmpty && !previewRedundant) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surfaceBase,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                inputPreview,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: colors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => onAnswer(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.danger,
                  side: BorderSide(color: colors.danger),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text(
                  l10n.approvalDeny,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => onAnswer(true),
                icon: const Icon(Icons.check_rounded, size: 14),
                label: Text(
                  l10n.approvalAllow,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Value-only marker of a tool call's key parameters (e.g. `ZSPD`), shown
/// to the right of the readable tool name — parameter names are
/// deliberately not displayed.
class _ParamChip extends StatelessWidget {
  const _ParamChip({required this.params});

  final List<String> params;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        params.join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
          fontFamily: 'monospace',
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

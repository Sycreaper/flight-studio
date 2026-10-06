import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../chat/chat_session.dart';
import '../theme/app_colors.dart';

/// Floating permission card shown when the Letta agent (or, later, an MCP
/// tool) requests approval for a tool call — the official `canUseTool`
/// bridge surfaces these through the gateway.
///
/// Style: welcome-screen floating card — pure white surface, NO border,
/// soft double shadow, large corner radius.
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

    final inputPreview = approval.input.entries
        .take(4)
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');

    return Container(
      width: 360,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.10),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
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
          Text(
            l10n.approvalWantsToUse(approval.tool),
            style: TextStyle(fontSize: 12.5, color: colors.textPrimary),
          ),
          if (inputPreview.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surfaceLowered,
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

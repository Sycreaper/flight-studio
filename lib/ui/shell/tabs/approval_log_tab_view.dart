import 'package:flutter/material.dart';

import '../../../data/ai/gateway_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../mcp/tool_display.dart';
import '../../theme/app_colors.dart';
import '../../widgets/center_card.dart';

/// The permission log of ONE conversation: every tool-permission decision
/// the gateway settled (user-approved, denied, auto-allowed, policy
/// blocks, timeouts), newest first, from the gateway's append-only audit
/// trail. Opened from the conversation drawer's ⋮ menu; the tab carries
/// the conversation's title.
///
/// Each entry renders as a card (reference: timeline log design): a
/// left colour bar encoding the granted access level (L0 grey, L1 green,
/// L2 amber, L3 red — tooltip states the level), the readable tool name
/// with its key-parameter chip, an outcome badge, the triggering turn
/// excerpt, and the timestamp right-aligned.
class ApprovalLogTabView extends StatefulWidget {
  const ApprovalLogTabView({
    super.key,
    required this.conversationId,
    this.onRevealContext,
  });

  final String conversationId;

  /// Invoked with one audit entry for the "jump to context" button —
  /// opens the conversation's chat tab scrolled to the audited exchange.
  /// Null hides the buttons.
  final ValueChanged<Map<String, dynamic>>? onRevealContext;

  @override
  State<ApprovalLogTabView> createState() => _ApprovalLogTabViewState();
}

class _ApprovalLogTabViewState extends State<ApprovalLogTabView> {
  List<Map<String, dynamic>>? _entries;
  bool _failed = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final entries = await GatewayClient.instance.fetchApprovalAudit(
      conversationId: widget.conversationId,
    );
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _failed = entries == null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final entries = _entries;

    return CenterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
          child: Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: colors.accent,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.approvalLogTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              if (entries != null) ...[
                const SizedBox(width: 10),
                Text(
                  '${entries.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                onPressed: _loading ? null : _load,
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 17,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _failed
                  ? Center(
                      child: Text(
                        l10n.approvalLogLoadFailed,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.textSecondary,
                        ),
                      ),
                    )
                  : entries == null || entries.isEmpty
                      ? Center(
                          child: Text(
                            l10n.approvalLogEmpty,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colors.textSecondary,
                            ),
                          ),
                        )
                      : Scrollbar(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                            itemCount: entries.length,
                            itemBuilder: (context, i) => _AuditCard(
                              entry: entries[i],
                              onRevealContext: widget.onRevealContext,
                            ),
                          ),
                        ),
        ),
      ],
      ),
    );
  }
}

/// One audit entry: the SAME compact one-line style the chat transcript
/// uses for resolved permission rows (gray surface, floating shadow,
/// "outcome · tool · key params"), with a left colour bar added that
/// encodes the granted access level (L0 grey, L1 green, L2 amber, L3 red —
/// tooltip states the rung) and the timestamp right-aligned.
class _AuditCard extends StatelessWidget {
  const _AuditCard({required this.entry, this.onRevealContext});

  final Map<String, dynamic> entry;
  final ValueChanged<Map<String, dynamic>>? onRevealContext;

  /// L0 grey — nothing granted, L1 green — public data, L2 amber —
  /// app-state reads, L3 red — confirmed writes (matches the ladder's
  /// semantics; tooltips carry the words).
  static const _levelColors = <Color>[
    Color(0xFF8B9197), // L0
    Color(0xFF1E8E3E), // L1
    Color(0xFFB26A00), // L2
    Color(0xFFD93025), // L3
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tool = '${entry['tool'] ?? ''}';
    final outcome = '${entry['outcome'] ?? ''}';
    final grantedLevel = (entry['grantedLevel'] as num?)?.toInt() ?? 0;
    final level = grantedLevel.clamp(0, 3);
    final rawInput = entry['input'];
    final input = rawInput is Map
        ? Map<String, dynamic>.from(rawInput)
        : const <String, dynamic>{};
    final ts = DateTime.tryParse('${entry['ts'] ?? ''}');

    final displayName = toolDisplayName(tool, l10n);
    final keyParams = toolKeyParams(tool, input);
    final (outcomeLabel, outcomeColor, outcomeIcon) = _outcomeStyle(
      outcome,
      l10n,
      colors,
    );

    String two(int v) => v.toString().padLeft(2, '0');
    // Audit timestamps are UTC ISO strings — render in the local zone.
    final local = ts?.toLocal();
    final timeText = local == null
        ? ''
        : '${two(local.month)}/${two(local.day)} '
            '${two(local.hour)}:${two(local.minute)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceLowered,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Level colour bar with a tooltip naming the rung.
            Tooltip(
              message: l10n.approvalLevelTooltip('L$level'),
              child: Container(width: 3, color: _levelColors[level]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: Row(
                  children: [
                    Icon(outcomeIcon, size: 14, color: outcomeColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$outcomeLabel · $displayName'
                        '${keyParams.isEmpty ? '' : ' ${keyParams.join(' · ')}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    if (timeText.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.textDisabled,
                        ),
                      ),
                    ],
                    // Jump to the audited exchange in the conversation.
                    if (onRevealContext != null &&
                        '${entry['turnExcerpt'] ?? ''}'.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _RevealButton(
                        onTap: () => onRevealContext!(entry),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, Color, IconData) _outcomeStyle(
    String outcome,
    AppLocalizations l10n,
    AppColors colors,
  ) {
    switch (outcome) {
      case 'approved':
        return (l10n.approvalOutcomeApproved, colors.success,
            Icons.check_circle_rounded);
      case 'auto-allowed':
        return (l10n.approvalOutcomeAutoAllowed, colors.success,
            Icons.done_all_rounded);
      case 'silent-allowed':
        return (l10n.approvalOutcomeSilentAllowed, colors.textSecondary,
            Icons.bolt_rounded);
      case 'denied':
        return (l10n.approvalOutcomeDenied, colors.danger,
            Icons.cancel_rounded);
      case 'denied-timeout':
        return (l10n.approvalOutcomeDeniedTimeout, colors.danger,
            Icons.timer_off_rounded);
      case 'policy-denied':
        return (l10n.approvalOutcomePolicyDenied, colors.danger,
            Icons.block_rounded);
      case 'fail-closed':
        return (l10n.approvalOutcomeFailClosed, colors.danger,
            Icons.lock_rounded);
      default:
        return (outcome, colors.textSecondary, Icons.help_outline_rounded);
    }
  }
}

/// Compact "jump to context" affordance at the end of an audit row.
class _RevealButton extends StatefulWidget {
  const _RevealButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_RevealButton> createState() => _RevealButtonState();
}

class _RevealButtonState extends State<_RevealButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: l10n.approvalRevealTooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Icon(
            Icons.center_focus_strong_rounded,
            size: 14,
            color: _hovering ? colors.accent : colors.textDisabled,
          ),
        ),
      ),
    );
  }
}

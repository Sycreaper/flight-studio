import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../../../data/settings/settings_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../mcp/tool_display.dart';
import '../../chat/chat_session.dart';
import '../../theme/app_colors.dart';
import '../../widgets/approval_card.dart';
import '../../widgets/center_card.dart';
import '../../widgets/model_reasoning_chips.dart';
import '../../widgets/prompt_box.dart';

/// Chat tab: ONE conversation with the flight-assistant agent — the message list
/// (in-memory — Letta keeps the authoritative conversation) above a
/// welcome-style prompt box. The model + reasoning chips
/// ([ModelReasoningChips]) are the same widget as the welcome page — both
/// surfaces share one selection owned by [ChatSessionManager].
class ChatTabView extends StatefulWidget {
  const ChatTabView({
    super.key,
    this.settings,
    required this.sessionKey,
  });

  final SettingsController? settings;

  /// [ChatSessionManager] key of the conversation this tab mirrors. A null
  /// session is impossible in practice (the shell always resolves a key);
  /// late binding would show an untitled draft chat.
  final String sessionKey;

  @override
  State<ChatTabView> createState() => _ChatTabViewState();
}

class _ChatTabViewState extends State<ChatTabView> {
  final _prompt = TextEditingController();
  final _historyController = ScrollController();
  late final ChatSession session;

  /// Pending permission-log jump (consumed after the next frame's build).
  AuditRevealRequest? _pendingReveal;

  @override
  void initState() {
    super.initState();
    final manager = ChatSessionManager.instance;
    var bound = manager.sessionByKey(widget.sessionKey);
    // Defensive: a tab whose session vanished (e.g. deleted conversation)
    // falls back to a fresh draft instead of crashing.
    bound ??= manager.sessionByKey(manager.newChat());
    session = bound!;
    session.addListener(_onSessionChanged);
    manager.auditRevealRequest.addListener(_onRevealRequest);
    _onRevealRequest(); // Consume a request raised before this tab existed.
    // Hydrate the conversation from Letta's official history API (no-op
    // when already loaded, a draft, or running in tests).
    session.loadHistory();
  }

  @override
  void dispose() {
    ChatSessionManager.instance.auditRevealRequest.removeListener(
      _onRevealRequest,
    );
    session.removeListener(_onSessionChanged);
    _prompt.dispose();
    _historyController.dispose();
    super.dispose();
  }

  /// Claims a pending permission-log jump when it targets THIS tab's
  /// conversation.
  void _onRevealRequest() {
    final request = ChatSessionManager.instance.auditRevealRequest.value;
    if (request == null) return;
    if (request.conversationId != session.conversationId) return;
    ChatSessionManager.instance.auditRevealRequest.value = null;
    _pendingReveal = request;
    if (mounted) setState(() {});
  }

  /// Scrolls to the user message whose turn triggered the audited call.
  /// The excerpt anchor is whitespace-folded and the trailing ellipsis is
  /// dropped before a prefix compare against the stored user texts.
  void _scrollToReveal() {
    final request = _pendingReveal;
    _pendingReveal = null;
    if (request == null) return;
    String fold(String s) => s
        .replaceAll('…', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    final anchor = fold(request.excerpt);
    if (anchor.isEmpty) return;
    for (var i = 0; i < session.messages.length; i++) {
      final m = session.messages[i];
      if (m.role != ChatRole.user || m.approval != null) continue;
      final text = fold(m.content);
      if (text.isEmpty) continue;
      if (text.startsWith(anchor.substring(
            0,
            anchor.length < 16 ? anchor.length : 16,
          )) ||
          anchor.startsWith(text.substring(
            0,
            text.length < 16 ? text.length : 16,
          ))) {
        final ctx = GlobalObjectKey(
          'msg_${widget.sessionKey}_$i',
        ).currentContext;
        Scrollable.ensureVisible(ctx!, alignment: 0.35);
        return;
      }
    }
  }

  /// Keep the latest message visible while streaming.
  void _onSessionChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_historyController.hasClients) return;
      _historyController.jumpTo(_historyController.position.maxScrollExtent);
    });
    setState(() {});
  }

  /// Builds one transcript row: permission rows render as embedded
  /// approval cards (spanning the reply-text width budget), everything
  /// else is a bubble with the streaming cursor on the live one.
  Widget _buildMessageItem(
    BuildContext context,
    ChatSession session,
    ChatMessage m,
    int i,
  ) {
    if (m.approval != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.6,
            ),
            child: _ApprovalTile(message: m, onAnswer: session.answerApproval),
          ),
        ),
      );
    }
    // The streaming cursor lives on the LAST real assistant message —
    // permission rows appended after it never take the cursor.
    var streamingIndex = -1;
    if (session.isStreaming) {
      for (var k = session.messages.length - 1; k >= 0; k--) {
        final c = session.messages[k];
        if (c.role == ChatRole.assistant && c.approval == null) {
          streamingIndex = k;
          break;
        }
      }
    }
    final streaming = i == streamingIndex;
    return _Bubble(
      role: m.role,
      content: streaming ? '${m.content} ▍' : m.content,
      // The status row stays while the turn is live — including pauses
      // between streamed segments (tool calls, reasoning) — and disappears
      // on turn_done/error.
      thinking: streaming,
      sessionPhase: session.phase,
      phaseDetail: session.phaseDetail,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingReveal != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToReveal());
    }
    return CenterCard(
      child: ListenableBuilder(
        listenable: session,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Message history ─────────────────────────────────────────
              Expanded(
                child: session.messages.isEmpty
                    ? const SizedBox.shrink() // Left empty; filled once the Letta loop lands.
                    : ListView.builder(
                        controller: _historyController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: session.messages.length,
                        itemBuilder: (context, i) {
                          final m = session.messages[i];
                          final item = _buildMessageItem(context, session, m, i);
                          // Stable object keys let the permission-log jump
                          // ensureVisible any row by index.
                          return KeyedSubtree(
                            key: GlobalObjectKey(
                              'msg_${widget.sessionKey}_$i',
                            ),
                            child: item,
                          );
                        },
                      ),
              ),
              // ── Prompt box + chips (same constraint → chips align with
              //    the box's left edge, like every chat surface) ─────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PromptBox(
                          controller: _prompt,
                          isStreaming: session.isStreaming,
                          onSend: session.send,
                          onStop: session.stop,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: ModelReasoningChips(
                              settings: widget.settings),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One chat bubble: user = accent-tinted, right-aligned; assistant =
/// Markdown-rendered raised-surface card (no border), left-aligned. Both
/// roles are text-selectable and carry a copy button. Error sentinels are
/// translated here so they follow the app language.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.role,
    required this.content,
    this.thinking = false,
    this.sessionPhase,
    this.phaseDetail,
  });

  final ChatRole role;
  final String content;

  /// Live phase of the running turn (thinking/searching/…) + the tool name
  /// driving it; rendered in the status row while [thinking].
  final ChatPhase? sessionPhase;
  final String? phaseDetail;

  /// Assistant turn started but nothing has streamed yet — show a status
  /// line ("Thinking…") instead of an empty body.
  final bool thinking;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final isUser = role == ChatRole.user;
    final display = switch (content) {
      kErrNoModel => l10n.chatErrNoModel,
      kErrGateway => l10n.chatErrGateway,
      kErrProvider => l10n.chatErrProvider,
      _ => content,
    };
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        constraints: BoxConstraints(
            maxWidth: MediaQuery
                .sizeOf(context)
                .width * 0.6),
        decoration: BoxDecoration(
          color: isUser
              ? colors.accent.withValues(alpha: 0.14)
              : colors.surfaceRaised,
          borderRadius: BorderRadius.circular(14).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Body: content when there is any (user text always; assistant
            // once the first delta arrived) — the thinking row renders in
            // ADDITION, not instead, so pauses mid-turn keep the status..
            // Assistant text is split into segments so <think> blocks fold
            // into a collapsible row
            if (isUser)
              SelectableText(
                display,
                style:
                TextStyle(fontSize: 12.5, color: colors.textPrimary),
              )
            else
              if (display.isNotEmpty && display != ' ▍')
                ..._buildAssistantSegments(
                  context,
                  display,
                  // A trailing cursor means the turn is still streaming —
                  // the active think block stays expanded until it closes.
                  streaming: display.endsWith('▍'),
                ),
            if (thinking)
              Padding(
                padding: EdgeInsets.only(
                  top: display.isNotEmpty && display != ' ▍' ? 6 : 0,
                ),
                child: _PhaseStatusRow(
                    phase: sessionPhase, detail: phaseDetail),
              ),
            _CopyButton(text: display),
          ],
        ),
      ),
    );
  }

  /// Splits assistant text into markdown segments and collapsible think
  /// blocks (`<think>…</think>`, `<thinking>…</thinking>`, and an unclosed
  /// trailing `<think>` while streaming). While streaming, the ACTIVE
  /// (last, unclosed) think block auto-expands; once the turn completes it
  /// auto-collapses again.
  static List<Widget> _buildAssistantSegments(
    BuildContext context,
    String display, {
    bool streaming = false,
  }) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final style = TextStyle(fontSize: 12.5, color: colors.textPrimary);
    final segments = <Widget>[];

    final thinkRegex = RegExp(
      r'<think(?:ing)?>([\s\S]*?)(?:</think(?:ing)?>|\s*▍$|$)',
      caseSensitive: false,
    );
    final matches = thinkRegex.allMatches(display).toList();
    var lastEnd = 0;
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final before = display.substring(lastEnd, match.start);
      if (before
          .trim()
          .isNotEmpty) {
        segments.add(SelectionArea(child: GptMarkdown(before, style: style)));
      }
      // The active block: the last one while a turn is still streaming AND
      // its closing tag hasn't arrived (the regex then matched through
      // end-of-input / the cursor instead of a `</think>`).
      final unclosed =
          !(match.group(0) ?? '').toLowerCase().contains('</think');
      final active = streaming && i == matches.length - 1 && unclosed;
      segments.add(
        _ThinkBlock(body: match.group(1)?.trim() ?? '', autoExpanded: active),
      );
      lastEnd = match.end;
    }
    final tail = display.substring(lastEnd);
    if (tail
        .trim()
        .isNotEmpty && tail.trim() != '▍') {
      segments.add(SelectionArea(child: GptMarkdown(tail, style: style)));
    }
    // Nothing but whitespace → keep the bubble non-empty for layout.
    if (segments.isEmpty) {
      segments.add(
        SelectionArea(child: GptMarkdown(display, style: style)),
      );
    }
    return segments;
  }
}

/// A folded `<think>` block: collapsed to a one-line toggle by default,
/// expands to the raw reasoning text in a subdued monospace block. While
/// [autoExpanded] is true (the live streaming block) it expands on its
/// own; when it flips false (the closing tag arrived / the turn finished)
/// it collapses again. A manual tap always wins until the auto state
/// changes.
class _ThinkBlock extends StatefulWidget {
  const _ThinkBlock({required this.body, this.autoExpanded = false});

  final String body;
  final bool autoExpanded;

  @override
  State<_ThinkBlock> createState() => _ThinkBlockState();
}

class _ThinkBlockState extends State<_ThinkBlock> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant _ThinkBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Follow the auto state only on TRANSITIONS, so a manual toggle during
    // streaming is respected until the block closes.
    if (widget.autoExpanded != oldWidget.autoExpanded) {
      setState(() => _expanded = widget.autoExpanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.psychology_alt_outlined,
                    size: 13,
                    color: colors.textDisabled,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${l10n.thinkBlockLabel} · ${widget.body.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textDisabled,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 120),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: colors.textDisabled,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surfaceLowered,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                widget.body,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: colors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Status row inside the streaming bubble: mini spinner + the live phase
/// label (thinking/searching/using tool…), tool name appended when known.
class _PhaseStatusRow extends StatelessWidget {
  const _PhaseStatusRow({this.phase, this.detail});

  final ChatPhase? phase;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final label = switch (phase) {
      ChatPhase.thinking => l10n.phaseThinking,
      ChatPhase.searching => l10n.phaseSearching,
      ChatPhase.reading => l10n.phaseReading,
      ChatPhase.writing => l10n.phaseWriting,
      ChatPhase.toolCall => detail == null
          ? l10n.phaseTool
          : '${l10n.phaseTool} · ${toolDisplayName(detail!, l10n)}',
      ChatPhase.waitingApproval => l10n.phaseWaitingApproval,
      _ => l10n.phaseWorking,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 11,
          height: 11,
          child: CircularProgressIndicator(
            strokeWidth: 1.4,
            valueColor: AlwaysStoppedAnimation(colors.textSecondary),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Subtle bottom-of-bubble copy button with brief "copied" feedback.
class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.text});

  final String text;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return Align(
      alignment: Alignment.centerRight,
      child: Tooltip(
        message: _copied ? l10n.chatCopied : l10n.chatCopy,
        waitDuration: const Duration(milliseconds: 500),
        child: InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: widget.text));
            setState(() => _copied = true);
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) setState(() => _copied = false);
            });
          },
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              _copied
                  ? Icons.check_rounded
                  : Icons.content_copy_rounded,
              size: 13,
              color: _copied ? colors.success : colors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }
}

/// One embedded tool-permission row in the transcript, spanning the full
/// reply-text width. Unanswered: the full [ApprovalCard] (allow / deny).
/// Answered: a static one-line summary (approved/denied/auto-allowed · readable
/// tool name · key params) — no expansion affordance.
class _ApprovalTile extends StatelessWidget {
  const _ApprovalTile({required this.message, required this.onAnswer});

  final ChatMessage message;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final m = message;
    final approval = m.approval!;

    if (!m.approvalResolved) {
      return ApprovalCard(
        approval: approval,
        onAnswer: onAnswer,
      );
    }

    // Collapsed summary row — gray (default input-box colour) with a
    // floating shadow, as wide as the reply text area.
    final autoAllowed = approval.autoAllowed;
    final autoDenied = approval.autoDenied;
    final outcomeKnown = m.approvalOutcomeKnown;
    final ok = m.approvalApproved;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Readable, localized tool name + value-only key-parameter marker
    // (e.g. `ZSPD`), mirroring the live permission card.
    final displayName = toolDisplayName(approval.tool, l10n);
    final keyParams = toolKeyParams(approval.tool, approval.input);
    // Restored cards with an audit outcome show the REAL decision.
    final audit = approval.auditOutcome;
    final auditOk = const ['approved', 'auto-allowed', 'silent-allowed']
        .contains(audit);
    final label = audit != null
        ? switch (audit) {
            'approved' => l10n.approvalOutcomeApproved,
            'auto-allowed' => l10n.approvalOutcomeAutoAllowed,
            'silent-allowed' => l10n.approvalOutcomeSilentAllowed,
            'denied' => l10n.approvalOutcomeDenied,
            'denied-timeout' => l10n.approvalOutcomeDeniedTimeout,
            'policy-denied' => l10n.approvalOutcomePolicyDenied,
            'fail-closed' => l10n.approvalOutcomeFailClosed,
            _ => l10n.approvalRestored,
          }
        : autoDenied
        ? l10n.approvalAutoDenied
        : autoAllowed
        ? l10n.approvalAutoAllowed
        : !outcomeKnown
        ? l10n.approvalRestored
        : ok
        ? l10n.approvalResolvedAllow
        : l10n.approvalResolvedDeny;
    final icon = audit != null
        ? (auditOk
              ? (audit == 'approved'
                    ? Icons.check_circle_rounded
                    : Icons.done_all_rounded)
              : (audit == 'denied-timeout'
                    ? Icons.timer_off_rounded
                    : audit == 'policy-denied'
                    ? Icons.block_rounded
                    : audit == 'fail-closed'
                    ? Icons.lock_rounded
                    : Icons.cancel_rounded))
        : autoDenied
        ? Icons.cancel_rounded
        : autoAllowed
        ? Icons.done_all_rounded
        : !outcomeKnown
        ? Icons.history_rounded
        : ok
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;
    final iconColor = audit != null
        ? (auditOk ? colors.success : colors.danger)
        : outcomeKnown && !autoDenied
        ? (ok ? colors.success : colors.danger)
        : autoDenied
        ? colors.danger
        : colors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: iconColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$label'
                  ' · $displayName'
                  '${keyParams.isEmpty ? '' : ' ${keyParams.join(' · ')}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

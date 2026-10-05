import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../../../data/settings/settings_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../chat/chat_session.dart';
import '../../theme/app_colors.dart';
import '../../widgets/center_card.dart';
import '../../widgets/model_reasoning_chips.dart';
import '../../widgets/prompt_box.dart';

/// Chat tab: the message history (in-memory — Letta keeps the authoritative
/// conversation) above a welcome-style prompt box. The model + reasoning
/// chips ([ModelReasoningChips]) are the same widget as the welcome page —
/// both surfaces share one selection owned by [ChatSession].
class ChatTabView extends StatefulWidget {
  const ChatTabView({super.key, this.settings});

  final SettingsController? settings;

  @override
  State<ChatTabView> createState() => _ChatTabViewState();
}

class _ChatTabViewState extends State<ChatTabView> {
  final _prompt = TextEditingController();
  final _historyController = ScrollController();

  @override
  void initState() {
    super.initState();
    ChatSession.instance.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    ChatSession.instance.removeListener(_onSessionChanged);
    _prompt.dispose();
    _historyController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final session = ChatSession.instance;
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
                    ? const SizedBox.shrink() // 留空：Letta 循环接入后填充
                    : ListView.builder(
                        controller: _historyController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: session.messages.length,
                        itemBuilder: (context, i) {
                          final m = session.messages[i];
                          final isLast = i == session.messages.length - 1;
                          final streaming =
                              isLast &&
                              m.role == ChatRole.assistant &&
                              session.isStreaming;
                          return _Bubble(
                            role: m.role,
                            content:
                            streaming ? '${m.content} ▍' : m.content,
                            // The status row stays while the turn is live —
                            // including pauses between streamed segments
                            // (tool calls, reasoning) — and disappears on
                            // turn_done/error.
                            thinking: streaming,
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
                          child: ModelReasoningChips(settings: widget.settings),
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
  const _Bubble(
      {required this.role, required this.content, this.thinking = false});

  final ChatRole role;
  final String content;

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
            // ADDITION, not instead, so pauses mid-turn keep the status.
            if (isUser)
              SelectableText(
                display,
                style:
                TextStyle(fontSize: 12.5, color: colors.textPrimary),
              )
            else
              if (display.isNotEmpty && display != ' ▍')
                SelectionArea(
                  child: GptMarkdown(
                    display,
                    style:
                    TextStyle(fontSize: 12.5, color: colors.textPrimary),
                  ),
                ),
            if (thinking)
              Padding(
                padding: EdgeInsets.only(
                  top: display.isNotEmpty && display != ' ▍' ? 6 : 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 11,
                      height: 11,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.4,
                        valueColor:
                        AlwaysStoppedAnimation(colors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.chatThinking,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            _CopyButton(text: display),
          ],
        ),
      ),
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

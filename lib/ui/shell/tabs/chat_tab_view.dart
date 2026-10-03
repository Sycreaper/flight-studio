import 'package:flutter/material.dart';
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
                          );
                        },
                      ),
              ),
              // ── Model + reasoning chips (shared with the welcome page) ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ModelReasoningChips(settings: widget.settings),
                ),
              ),
              // ── Prompt box (same as the welcome screen) ─────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: PromptBox(
                      controller: _prompt,
                      isStreaming: session.isStreaming,
                      onSend: session.send,
                      onStop: session.stop,
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
/// Markdown-rendered raised-surface card, left-aligned. Error sentinels are
/// translated here so they follow the app language.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.role, required this.content});

  final ChatRole role;
  final String content;

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          border: isUser ? null : Border.all(color: colors.border),
        ),
        child: isUser
            ? SelectableText(
          display,
          style:
          TextStyle(fontSize: 12.5, color: colors.textPrimary),
              )
            : GptMarkdown(
          display,
          style:
          TextStyle(fontSize: 12.5, color: colors.textPrimary),
        ),
      ),
    );
  }
}

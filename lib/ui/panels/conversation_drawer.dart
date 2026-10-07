import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../chat/chat_session.dart';
import '../theme/app_colors.dart';

/// Left-drawer panel listing every conversation with the 飞行助理 agent
/// (official Letta conversations API via [ChatSessionManager]).
///
/// Top: a 新建对话 button that opens a fresh chat tab. Below: the
/// conversation list — click opens (or focuses) the matching chat tab; the
/// trailing ⋮ menu offers 删除对话 behind a confirmation dialog (deletion
/// uses the official archive semantics; an actively streaming conversation
/// is aborted first, gateway-side).
class ConversationDrawer extends StatefulWidget {
  const ConversationDrawer({
    super.key,
    required this.onCreateChat,
    required this.onOpenConversation,
  });

  /// Opens a new chat tab (新对话).
  final VoidCallback onCreateChat;

  /// Opens (or focuses) the chat tab of one conversation id.
  final ValueChanged<String> onOpenConversation;

  @override
  State<ConversationDrawer> createState() => _ConversationDrawerState();
}

class _ConversationDrawerState extends State<ConversationDrawer> {
  @override
  void initState() {
    super.initState();
    final manager = ChatSessionManager.instance;
    manager.addListener(_onManagerChanged);
    // Passive refresh — loads whatever the gateway already knows without
    // blocking the drawer (the list fills once Letta is reachable).
    manager.refreshConversations();
  }

  void _onManagerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ChatSessionManager.instance.removeListener(_onManagerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final conversations = ChatSessionManager.instance.conversations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          child: OutlinedButton.icon(
            onPressed: widget.onCreateChat,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.accent,
              side: BorderSide(color: colors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            icon: Icon(Icons.add_comment_outlined,
                size: 15, color: colors.accent),
            label: Text(
              l10n.conversationNew,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Expanded(
          child: conversations.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.conversationEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textDisabled,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(6, 2, 6, 8),
                  itemCount: conversations.length,
                  itemBuilder: (context, i) =>
                      _ConversationRow(
                    conversation: conversations[i],
                    onOpen: () =>
                        widget.onOpenConversation(conversations[i].id),
                    onDelete: () => _confirmDelete(conversations[i].id),
                  ),
                ),
        ),
      ],
    );
  }

  /// 删除对话 confirm dialog — deletion cannot be undone.
  Future<void> _confirmDelete(String id) async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.border),
        ),
        title: Text(
          l10n.conversationDelete,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          l10n.conversationDeleteConfirm,
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l10n.settingsCancel,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.conversationDeleteAction,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.danger,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ChatSessionManager.instance.deleteConversation(id);
    }
  }
}

/// One conversation row: title (新对话 placeholder until summarized),
/// relative activity time, trailing ⋮ menu with 删除对话.
class _ConversationRow extends StatefulWidget {
  const _ConversationRow({
    required this.conversation,
    required this.onOpen,
    required this.onDelete,
  });

  final GatewayConversation conversation;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  State<_ConversationRow> createState() => _ConversationRowState();
}

class _ConversationRowState extends State<_ConversationRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final c = widget.conversation;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onOpen,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.fromLTRB(8, 6, 2, 6),
          decoration: BoxDecoration(
            color: _hovering
                ? colors.surfaceRaised.withValues(alpha: 0.7)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 14,
                color: colors.textDisabled,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title ?? l10n.chatNewConversation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (c.lastMessageAt != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        _shortTime(c.lastMessageAt!),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: colors.textDisabled,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // ⋮ menu — always laid out so hover doesn't shift the row.
              SizedBox(
                width: 24,
                height: 24,
                child: PopupMenuButton<String>(
                  tooltip: '',
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 15,
                    color: _hovering
                        ? colors.textSecondary
                        : colors.textDisabled,
                  ),
                  color: colors.surfaceRaised,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: colors.border),
                  ),
                  elevation: 8,
                  padding: EdgeInsets.zero,
                  position: PopupMenuPosition.under,
                  onSelected: (value) {
                    if (value == 'delete') widget.onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      height: 36,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 15, color: colors.danger),
                          const SizedBox(width: 8),
                          Text(
                            l10n.conversationDelete,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact local time of the last activity (best-effort ISO parse).
  String _shortTime(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (dt.isAfter(today)) {
      String two(int v) => v.toString().padLeft(2, '0');
      return '${two(dt.hour)}:${two(dt.minute)}';
    }
    return '${dt.month}/${dt.day}';
  }
}

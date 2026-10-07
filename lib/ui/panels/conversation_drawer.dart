import 'dart:convert';
import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Uint8List;

import '../../l10n/app_localizations.dart';
import '../chat/chat_session.dart';
import '../theme/app_colors.dart';
import '../widgets/floating_window.dart';

/// Left-drawer panel listing every conversation with the 飞行助理 agent
/// (official Letta conversations API via [ChatSessionManager]).
///
/// Top: a 新建对话 button that opens a fresh chat tab. Below: the
/// conversation list — click opens (or focuses) the matching chat tab; the
/// trailing ⋮ menu offers 导出对话 (Markdown file) and 删除对话 behind a
/// confirmation floating window (deletion uses the official archive
/// semantics; an actively streaming conversation is aborted first,
/// gateway-side).
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
                    onExport: () => _exportMarkdown(conversations[i].id),
                  ),
                ),
        ),
      ],
    );
  }

  /// 删除对话 confirm floating window — the same style the settings page
  /// uses for destructive confirmations. Deletion cannot be undone.
  void _confirmDelete(String id) {
    final l10n = AppLocalizations.of(context)!;
    late OverlayEntry confirmEntry;
    confirmEntry = OverlayEntry(
      builder: (ctx) => FloatingWindow(
        title: l10n.conversationDelete,
        titleIcon: Icons.warning_amber_rounded,
        width: 400,
        height: 200,
        onClose: () => confirmEntry.remove(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Builder(
            builder: (ctx) {
              final colors = Theme.of(ctx).extension<AppColors>()!;
              return Column(
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 32,
                    color: colors.danger,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.conversationDeleteConfirm,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => confirmEntry.remove(),
                        child: Text(
                          l10n.settingsCancel,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.danger,
                        ),
                        onPressed: () {
                          confirmEntry.remove();
                          ChatSessionManager.instance.deleteConversation(id);
                        },
                        child: Text(
                          l10n.conversationDeleteAction,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    Overlay.of(context).insert(confirmEntry);
  }

  /// 导出对话 — one Markdown file (title header + user/assistant turns)
  /// written through the platform save dialog.
  Future<void> _exportMarkdown(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final manager = ChatSessionManager.instance;
    final title = manager.titleOf(id);
    final messages = await manager.exportMessages(id);
    if (!mounted) return;
    if (messages == null || messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.conversationEmpty)),
      );
      return;
    }

    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final buffer = StringBuffer()
      ..writeln('# ${title ?? l10n.chatNewConversation}')
      ..writeln()
      ..writeln(
        '> Flight Studio · ${l10n.conversationExport} · '
        '${now.year}-${two(now.month)}-${two(now.day)} '
        '${two(now.hour)}:${two(now.minute)}',
      );
    for (final m in messages) {
      buffer
        ..writeln()
        ..writeln('## ${m.role == 'user'
            ? l10n.conversationExportUser
            : l10n.conversationExportAssistant}')
        ..writeln()
        ..writeln(m.content);
    }

    final safeTitle = (title ?? id)
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();
    final fileName =
        '${safeTitle.isEmpty ? 'conversation' : safeTitle}_'
        '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}.md';
    final uri = await FilePicker.saveFile(
      dialogTitle: l10n.conversationExport,
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(buffer.toString())),
    );
    if (uri == null || !mounted) return; // Cancelled.
    // Some platforms return the uri without writing the bytes themselves.
    final file = File(uri.toFilePath());
    if (!file.existsSync()) {
      await file.writeAsString(buffer.toString(), flush: true);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.conversationExportDone}: ${file.path}')),
    );
  }
}

/// One conversation row: title (新对话 placeholder until summarized),
/// relative activity time, trailing ⋮ menu with 导出对话 / 删除对话.
class _ConversationRow extends StatefulWidget {
  const _ConversationRow({
    required this.conversation,
    required this.onOpen,
    required this.onDelete,
    required this.onExport,
  });

  final GatewayConversation conversation;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback onExport;

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
                    if (value == 'export') widget.onExport();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'export',
                      height: 36,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.file_download_outlined,
                              size: 15, color: colors.accent),
                          const SizedBox(width: 8),
                          Text(
                            l10n.conversationExport,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
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

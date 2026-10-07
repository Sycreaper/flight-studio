import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/logging/app_log.dart';
import '../../data/ai/gateway_client.dart';
import '../../data/ai/gateway_process.dart';
import '../../data/settings/api_key_entry.dart';

export '../../data/ai/gateway_client.dart' show GatewayConversation;

enum ChatRole { user, assistant }

/// Live phase of the running turn, mapped from the OFFICIAL Letta stream
/// (loop_status / tool_call / reasoning) — extensible for MCP tools: a
/// custom tool surfaces as [toolCall] with its name in `phaseDetail`.
enum ChatPhase {
  idle,
  thinking,
  searching,
  reading,
  writing,
  toolCall,
  waitingApproval,
  working
}

/// One pending tool-approval request surfaced by the gateway's official
/// canUseTool bridge (reusable for MCP tool approvals).
class PendingApproval {
  PendingApproval({required this.id, required this.tool, required this.input});

  final String id;
  final String tool;
  final Map<String, dynamic> input;
}

/// One chat bubble. [done] is `false` while an assistant reply is still
/// streaming in.
class ChatMessage {
  ChatMessage({required this.role, required this.content, this.done = true});

  final ChatRole role;
  String content;
  bool done;
}

/// Sentinel bubble contents — the UI translates these at render time so the
/// raw strings never leak untranslated into the chat history.
const kErrNoModel = '<<flightstudio:no_model>>';
const kErrGateway = '<<flightstudio:gateway_not_ready>>';
const kErrProvider = '<<flightstudio:provider_rejected>>';

/// In-memory state of ONE conversation with the 飞行助理 agent.
///
/// A session starts as a **draft** ([conversationId] null — the UI labels it
/// 新对话). The first [send] creates the Letta conversation lazily — after
/// the provider push succeeded — and binds the id, so failed turns never
/// leave ghost conversations behind. Replies stream from the gateway's SSE
/// channel, dispatched here by [ChatSessionManager]; history hydration uses
/// the official Letta API (the app never records chat itself).
class ChatSession extends ChangeNotifier {
  ChatSession({this.conversationId});

  /// The Letta conversation this session mirrors; null while still a draft.
  String? conversationId;

  final List<ChatMessage> messages = [];

  bool _streaming = false;

  bool get isStreaming => _streaming;

  /// Live turn phase (思考中/搜索中/…) + the tool name driving it, from the
  /// official stream. Cleared when the turn ends.
  ChatPhase _phase = ChatPhase.idle;
  String? _phaseDetail;

  ChatPhase get phase => _phase;
  String? get phaseDetail => _phaseDetail;

  void _setPhase(ChatPhase value, {String? detail}) {
    if (_phase == value && _phaseDetail == detail) return;
    _phase = value;
    _phaseDetail = detail;
    notifyListeners();
  }

  static ChatPhase _phaseFromWire(String? raw) =>
      switch (raw) {
        'thinking' => ChatPhase.thinking,
        'searching' => ChatPhase.searching,
        'reading' => ChatPhase.reading,
        'writing' => ChatPhase.writing,
        'tool' => ChatPhase.toolCall,
        'waitingApproval' => ChatPhase.waitingApproval,
        'working' => ChatPhase.working,
        _ => ChatPhase.working,
      };

  /// Pending tool approval (permission card). Null when none.
  PendingApproval? pendingApproval;

  /// Structured log entry (app-*.log). Secrets are never logged — only
  /// lengths and ids.
  void _diag(String message) => AppLog.i('chat', message);

  // ── Outbound turn ─────────────────────────────────────────────────────────

  /// Appends the user message and starts the 飞行助理 turn via the gateway:
  /// ensure gateway process → push provider credentials → (drafts only)
  /// create the conversation → send. No-op while a reply is already
  /// streaming or the text is empty.
  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _streaming) return;

    messages.add(ChatMessage(role: ChatRole.user, content: trimmed));
    messages.add(
      ChatMessage(role: ChatRole.assistant, content: '', done: false),
    );

    // Test environment: no gateway available — complete the turn immediately
    // so tests don't hang on HTTP timeouts or pending dio timers.
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      messages.last.done = true;
      notifyListeners();
      return;
    }

    _streaming = true;
    notifyListeners();

    void fail(String sentinel) {
      messages.last
        ..done = true
        ..content = sentinel;
      _streaming = false;
      notifyListeners();
    }

    final manager = ChatSessionManager.instance;
    final key = manager.selectedKey;
    final model = manager.selectedModelId;
    _diag('send: keyId=${key?.id} type=${key?.type} model=$model '
        'baseUrlLen=${key?.baseUrl?.length ?? 0} valueLen=${key?.value.length ??
        0}');
    if (key == null || model == null ||
        key.type != ApiKeyType.openAiCompatible) {
      fail(kErrNoModel);
      return;
    }

    // 1. Gateway subprocess up.
    final running = await GatewayProcess.instance.ensureRunning();
    _diag('ensureRunning: $running');
    if (!running) {
      fail(kErrGateway);
      return;
    }

    // 2. Lend the credential + switch model (official Letta protocol).
    // Failures surface the gateway/Letta error text verbatim (English) for
    // diagnostics — the user asked to see the raw reason.
    try {
      await GatewayClient.instance.setProvider(
        apiKey: key.value,
        baseUrl: key.baseUrl ?? '',
        model: model,
        reasoningEffort: manager.reasoningEffort,
      );
      _diag('setProvider: ok');
    } on GatewayApiException catch (e) {
      _diag('setProvider FAIL (GatewayApiException): ${e.message}');
      fail('Letta: ${e.message}');
      return;
    } on Exception catch (e) {
      _diag('setProvider FAIL ($e)');
      fail('Letta: $e');
      return;
    }

    // 3. Drafts: create the conversation now that the turn is viable.
    if (conversationId == null) {
      final id = await GatewayClient.instance.createConversation();
      if (id == null || id.isEmpty) {
        _diag('createConversation: failed');
        fail(kErrGateway);
        return;
      }
      conversationId = id;
      _diag('conversation created: $id');
      manager.onConversationBound(this);
    }

    // 4. SSE events flow through the manager's global subscription.
    manager.startSse();
    manager.streamingSession = this;

    // 5. Fire the turn. Rejections carry the gateway's reason verbatim.
    final rejectReason = await GatewayClient.instance.sendMessage(
      trimmed,
      conversationId: conversationId,
    );
    _diag('sendMessage: ${rejectReason ?? 'accepted'}');
    if (rejectReason != null) {
      manager.streamingSession = null;
      fail('Letta: $rejectReason');
    }
  }

  /// Sends the user's decision on the pending tool approval (permission
  /// card) through the official approval endpoint.
  void answerApproval(bool approve) {
    final approval = pendingApproval;
    if (approval == null) return;
    pendingApproval = null;
    notifyListeners();
    GatewayClient.instance.resolveApproval(
      approval.id,
      approve: approve,
    );
  }

  /// Aborts the running turn via the gateway's stop endpoint, keeping
  /// whatever text already streamed in.
  void stop() {
    if (!_streaming) return;
    _streaming = false;
    _setPhase(ChatPhase.idle);
    if (ChatSessionManager.instance.streamingSession == this) {
      ChatSessionManager.instance.streamingSession = null;
    }
    GatewayClient.instance.stop();
    notifyListeners();
  }

  // ── Inbound SSE dispatch (called by [ChatSessionManager]) ─────────────────

  void onPhase(String? phase, String? detail) =>
      _setPhase(_phaseFromWire(phase), detail: detail);

  void onDelta(String content) {
    if (content.isEmpty || messages.isEmpty) return;
    final last = messages.last;
    if (last.role == ChatRole.assistant) {
      // Each SSE delta is an INCREMENTAL chunk — append it.
      last.content += content;
      notifyListeners();
    }
  }

  void onTurnDone(String? content) {
    if (content != null && content.isNotEmpty && messages.isNotEmpty) {
      messages.last.content = content;
    }
    messages.last.done = true;
    _streaming = false;
    _setPhase(ChatPhase.idle);
    notifyListeners();
  }

  void onTurnError(String message) {
    if (messages.isNotEmpty) {
      messages.last
        ..done = true
        ..content = message;
    }
    _streaming = false;
    _setPhase(ChatPhase.idle);
    notifyListeners();
  }

  void onApprovalRequest(String id, String tool, Map<String, dynamic> input) {
    pendingApproval = PendingApproval(id: id, tool: tool, input: input);
    _diag('approval request: $tool ($id)');
    notifyListeners();
  }

  void onApprovalResolved(String? id) {
    if (pendingApproval?.id == id) {
      pendingApproval = null;
      _setPhase(ChatPhase.working);
      notifyListeners();
    }
  }

  // ── History ───────────────────────────────────────────────────────────────

  bool _historyLoaded = false;

  /// Hydrates the conversation from Letta's official history API (no-op for
  /// drafts, already-loaded sessions and tests).
  Future<void> loadHistory() async {
    if (_historyLoaded || _streaming || conversationId == null) return;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    _historyLoaded = true;
    if (!await GatewayProcess.instance.ensureRunning()) return;
    final history = await GatewayClient.instance.fetchHistory(
      conversationId: conversationId,
    );
    if (history == null || history.isEmpty || _streaming ||
        conversationId == null) {
      return;
    }
    if (messages.isNotEmpty) return;
    messages.addAll([
      for (final m in history)
        ChatMessage(
          role: m.role == 'user' ? ChatRole.user : ChatRole.assistant,
          content: m.content,
        ),
    ]);
    notifyListeners();
  }

  /// Test-only: forgets the history-loaded guard.
  @visibleForTesting
  void resetForTest() {
    _streaming = false;
    messages.clear();
    notifyListeners();
  }
}

/// App-global owner of the conversation list, the per-conversation
/// [ChatSession]s and the SHARED model selection (which API key entry backs
/// the chat and which model / reasoning effort to use) so every surface
/// (welcome page, chat tabs, chips) shows the same choice.
///
/// All conversations belong to the single 飞行助理 agent; the list mirrors
/// Letta's official conversations API. The manager also owns ONE SSE
/// subscription to the gateway and dispatches each event to the session
/// matching its `conversationId` — sessions never subscribe individually.
class ChatSessionManager extends ChangeNotifier {
  ChatSessionManager._();

  static final ChatSessionManager instance = ChatSessionManager._();

  /// Conversations of 飞行助理, newest activity first (official API).
  final List<GatewayConversation> conversations = [];

  /// Session owning the live turn (null while idle) — the fallback target
  /// for SSE events that carry no conversation tag.
  ChatSession? streamingSession;

  final Map<String, ChatSession> _sessions = {};
  int _draftCounter = 0;

  // ── Session lifecycle ─────────────────────────────────────────────────────

  /// Creates a fresh draft session (新对话) and returns its key. The Letta
  /// conversation is created lazily on the session's first send.
  String newChat() {
    final key = 'draft_${++_draftCounter}';
    _sessions[key] = ChatSession();
    return key;
  }

  /// Returns the session key for an existing conversation, creating the
  /// session (with lazy history hydration) when needed.
  String openConversation(String conversationId) {
    final key = 'conv_$conversationId';
    _sessions.putIfAbsent(
      key,
      () => ChatSession()..conversationId = conversationId,
    );
    return key;
  }

  /// The session registered under [key], or null.
  ChatSession? sessionByKey(String? key) =>
      key == null ? null : _sessions[key];

  /// Binds a draft session that just created its conversation into the
  /// conversation list (called by [ChatSession.send]).
  void onConversationBound(ChatSession session) {
    final id = session.conversationId;
    if (id == null) return;
    conversations.insert(
      0,
      GatewayConversation(id: id, title: null, lastMessageAt: null),
    );
    notifyListeners();
  }

  /// Deletes one conversation (official archive semantics) and drops its
  /// session. The UI closes the matching tab itself before calling this.
  Future<void> deleteConversation(String id) async {
    await GatewayClient.instance.deleteConversation(id);
    conversations.removeWhere((c) => c.id == id);
    _sessions.removeWhere((_, s) => s.conversationId == id);
    if (streamingSession?.conversationId == id) streamingSession = null;
    notifyListeners();
  }

  /// Reloads the conversation list from the official Letta API (starts the
  /// gateway when needed, mirroring the old chat-tab hydration behaviour).
  Future<void> refreshConversations() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    if (!await GatewayProcess.instance.ensureRunning()) return;
    final list = await GatewayClient.instance.fetchConversations();
    if (list == null) return;
    conversations
      ..clear()
      ..addAll(list);
    notifyListeners();
  }

  /// Display title of a conversation, or null when not (yet) summarized.
  String? titleOf(String conversationId) {
    for (final c in conversations) {
      if (c.id == conversationId) return c.title;
    }
    return null;
  }

  /// Stops whichever session is streaming (stop button on any surface).
  void stopStreaming() => streamingSession?.stop();

  // ── Shared model selection ────────────────────────────────────────────────

  /// Selected OpenAI-compatible API key entry (credentials + models).
  ApiKeyEntry? selectedKey;

  /// Selected model id — one of [ApiKeyEntry.models] (discovered from the
  /// endpoint's /models listing when the key was created).
  String? selectedModelId;
  String _reasoningEffort = 'medium';

  String get reasoningEffort => _reasoningEffort;

  set reasoningEffort(String value) {
    if (_reasoningEffort == value) return;
    _reasoningEffort = value;
    _persistSelection();
    notifyListeners();
  }

  void selectKey(ApiKeyEntry? key, {String? modelId}) {
    selectedKey = key;
    // Default to the first discovered model when none given explicitly.
    selectedModelId =
        modelId ??
            (key != null && key.models.isNotEmpty ? key.models.first : null);
    _persistSelection();
    notifyListeners();
  }

  static const _selectedKeyPref = 'chat.selectedKeyId';
  static const _selectedModelPref = 'chat.selectedModelId';
  static const _reasoningPref = 'chat.reasoningEffort';
  bool _restoreAttempted = false;

  Future<void> _persistSelection() async {
    try {
      final prefs = SharedPreferencesAsync();
      await prefs.setString(_selectedKeyPref, selectedKey?.id ?? '');
      await prefs.setString(_selectedModelPref, selectedModelId ?? '');
      await prefs.setString(_reasoningPref, _reasoningEffort);
    } on Exception {
      // Best-effort — selection persistence is a convenience.
    }
  }

  /// Restores the last selection from prefs. Called once from the model
  /// chips when they have the key list available.
  Future<void> restoreSelection(List<ApiKeyEntry> keys) async {
    if (_restoreAttempted) return;
    _restoreAttempted = true;
    try {
      final prefs = SharedPreferencesAsync();
      final effort = await prefs.getString(_reasoningPref);
      if (effort != null && effort.isNotEmpty) _reasoningEffort = effort;
      final id = await prefs.getString(_selectedKeyPref);
      if (id != null && id.isNotEmpty) {
        selectedKey = keys.where((k) => k.id == id).firstOrNull;
        if (selectedKey != null) {
          final savedModel = await prefs.getString(_selectedModelPref);
          final hasModel = savedModel != null &&
              selectedKey!.models.contains(savedModel);
          selectedModelId = hasModel
              ? savedModel
              : (selectedKey!.models.isNotEmpty
              ? selectedKey!.models.first
              : null);
          notifyListeners();
        }
      }
    } on Exception {
      // Best-effort.
    }
  }

  // ── Global SSE dispatch ───────────────────────────────────────────────────

  StreamSubscription<Map<String, dynamic>>? _eventSub;
  bool _sseStarted = false;

  void _diag(String message) => AppLog.i('chat-manager', message);

  /// Ensures exactly ONE subscription to the gateway's SSE stream exists.
  /// It survives across turns; a dropped stream is reconnected by the next
  /// [send].
  void startSse() {
    if (_sseStarted) return;
    _sseStarted = true;
    _eventSub = GatewayClient.instance.events().listen(
      _onEvent,
      onError: (Object e) {
        _diag('sse stream error: $e');
        streamingSession?.onTurnError('SSE: $e');
        streamingSession = null;
        _sseStarted = false;
      },
      onDone: () {
        _diag('sse stream done');
        _sseStarted = false;
      },
    );
  }

  void _onEvent(Map<String, dynamic> event) {
    final type = event['event'] as String?;
    final conversationId = event['conversationId'] as String?;
    _diag('sse event: $type conv=$conversationId');

    if (type == 'conversation_renamed') {
      final id = event['conversationId'] as String?;
      final title = event['title'] as String?;
      if (id == null || title == null || title.isEmpty) return;
      final index = conversations.indexWhere((c) => c.id == id);
      if (index >= 0) {
        final old = conversations.removeAt(index);
        conversations.insert(
          index,
          GatewayConversation(
            id: old.id,
            title: title,
            lastMessageAt: DateTime.now().toUtc().toIso8601String(),
          ),
        );
      } else {
        conversations.insert(
          0,
          GatewayConversation(
            id: id,
            title: title,
            lastMessageAt: DateTime.now().toUtc().toIso8601String(),
          ),
        );
      }
      notifyListeners();
      return;
    }

    ChatSession? target;
    if (conversationId != null) {
      for (final s in _sessions.values) {
        if (s.conversationId == conversationId) {
          target = s;
          break;
        }
      }
    }
    // Untagged events belong to whichever session holds the live turn
    // (default-conversation compat).
    target ??= streamingSession;
    if (target == null) return;

    switch (type) {
      case 'phase':
        target.onPhase(
          event['phase'] as String?,
          event['detail'] as String?,
        );
      case 'delta':
        target.onDelta(event['content'] as String? ?? '');
      case 'turn_done':
        if (streamingSession == target) streamingSession = null;
        target.onTurnDone(event['content'] as String?);
        // Keep the drawer's activity order fresh.
        _touchConversation(target.conversationId);
      case 'error':
        if (streamingSession == target) streamingSession = null;
        target.onTurnError(
          event['message'] as String? ?? 'Unknown error',
        );
      case 'approval_request':
        final id = event['id'] as String?;
        final tool = event['tool'] as String? ?? '';
        if (id != null) {
          final rawInput = event['input'];
          target.onApprovalRequest(
            id,
            tool,
            rawInput is Map
                ? Map<String, dynamic>.from(rawInput)
                : const {},
          );
        }
      case 'approval_resolved':
        target.onApprovalResolved(event['id'] as String?);
    }
  }

  void _touchConversation(String? id) {
    if (id == null) return;
    final index = conversations.indexWhere((c) => c.id == id);
    if (index <= 0) return;
    final c = conversations.removeAt(index);
    conversations.insert(
      0,
      GatewayConversation(
        id: c.id,
        title: c.title,
        lastMessageAt: DateTime.now().toUtc().toIso8601String(),
      ),
    );
    notifyListeners();
  }

  /// Test-only: resets every conversation and session.
  @visibleForTesting
  void resetForTest() {
    _eventSub?.cancel();
    _sseStarted = false;
    streamingSession = null;
    conversations.clear();
    _sessions.clear();
    notifyListeners();
  }

  /// Test-only: feeds one decoded SSE event straight into the dispatcher.
  @visibleForTesting
  void dispatchTestEvent(Map<String, dynamic> event) => _onEvent(event);
}

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/logging/app_log.dart';
import '../../data/ai/gateway_client.dart';
import '../../data/ai/gateway_process.dart';
import '../../data/settings/api_key_entry.dart';

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

/// In-memory chat state shared between the welcome-screen prompt box and the
/// chat tab (app-global so a send on either surface lands in the same
/// conversation).
///
/// It also owns the **shared model selection** (which API key entry backs
/// the chat and which model / reasoning effort to use) so the welcome page
/// and the chat tab always show the same choice.
///
/// Replies come from the **Letta agent** via the Agent Gateway's SSE stream.
/// History is intentionally **not persisted** — Letta keeps the authoritative
/// conversation on its side.
class ChatSession extends ChangeNotifier {
  ChatSession._();

  static final ChatSession instance = ChatSession._();

  final List<ChatMessage> messages = [];

  bool _streaming = false;

  bool get isStreaming => _streaming;

  /// Live turn phase (思考中/搜索中/…) + the tool name driving it, from
  /// the official stream. Cleared when the turn ends.
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
    notifyListeners();
  }

  StreamSubscription<Map<String, dynamic>>? _eventSub;

  /// Structured log entry (app-*.log). Secrets are never logged — only
  /// lengths and ids.
  void _diag(String message) => AppLog.i('chat', message);

  void selectKey(ApiKeyEntry? key, {String? modelId}) {
    selectedKey = key;
    // Default to the first discovered model when none given explicitly.
    selectedModelId =
        modelId ??
            (key != null && key.models.isNotEmpty ? key.models.first : null);
    _persistSelection();
    notifyListeners();
  }

  // ── Selection persistence (survives app restarts) ────────────────────────

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

  //// Appends the user message and starts the Letta agent turn via the
  /// gateway: ensure gateway process → push provider credentials → send.
  /// No-op while a reply is already streaming or the text is empty.
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

    final key = selectedKey;
    final model = selectedModelId;
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
        reasoningEffort: reasoningEffort,
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

    // 3. Subscribe to the SSE event stream for streaming deltas.
    _eventSub?.cancel();
    _eventSub = GatewayClient.instance.events().listen(
      (event) {
        final type = event['event'] as String?;
        _diag('sse event: $type');
        switch (type) {
          case 'phase':
            _setPhase(
              _phaseFromWire(event['phase'] as String?),
              detail: event['detail'] as String?,
            );
          case 'delta':
            final content = event['content'] as String?;
            if (content != null && messages.isNotEmpty) {
              final last = messages.last;
              if (last.role == ChatRole.assistant) {
                // Each SSE delta is an INCREMENTAL chunk — append it.
                last.content += content;
                notifyListeners();
              }
            }
          case 'turn_done':
            final content = event['content'] as String?;
            if (content != null && content.isNotEmpty && messages.isNotEmpty) {
              messages.last.content = content;
            }
            messages.last.done = true;
            _streaming = false;
            _setPhase(ChatPhase.idle);
            notifyListeners();
          case 'error':
            final message = event['message'] as String? ?? 'Unknown error';
            if (messages.isNotEmpty) {
              messages.last
                ..done = true
                ..content = message;
            }
            _streaming = false;
            _setPhase(ChatPhase.idle);
            notifyListeners();
          case 'approval_request':
            final id = event['id'] as String?;
            final tool = event['tool'] as String? ?? '';
            if (id != null) {
              final rawInput = event['input'];
              pendingApproval = PendingApproval(
                id: id,
                tool: tool,
                input: rawInput is Map
                    ? Map<String, dynamic>.from(rawInput)
                    : const {},
              );
              _diag('approval request: $tool ($id)');
              notifyListeners();
            }
          case 'approval_resolved':
            final id = event['id'] as String?;
            if (pendingApproval?.id == id) {
              pendingApproval = null;
              _setPhase(ChatPhase.working);
              notifyListeners();
            }
        }
      },
      onError: (Object e) {
        _diag('sse stream error: $e');
        _streaming = false;
        notifyListeners();
      },
      onDone: () => _diag('sse stream done'),
    );

    // 4. Fire the turn. Rejections carry the gateway's reason verbatim.
    final rejectReason = await GatewayClient.instance.sendMessage(trimmed);
    _diag('sendMessage: ${rejectReason ?? 'accepted'}');
    if (rejectReason != null) {
      _eventSub?.cancel();
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
    GatewayClient.instance.stop();
    notifyListeners();
  }

  /// Test-only: resets the in-memory conversation.
  @visibleForTesting
  void resetForTest() {
    _eventSub?.cancel();
    _streaming = false;
    messages.clear();
    notifyListeners();
  }

  // ── History (official Letta API — never self-recorded) ────────────────────

  bool _historyLoaded = false;

  /// Loads the persisted conversation from Letta once, when the local
  /// history is still empty (fresh app session). Called from the chat tab.
  Future<void> loadHistory() async {
    if (_historyLoaded || _streaming || messages.isNotEmpty) return;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    _historyLoaded = true;
    if (!await GatewayProcess.instance.ensureRunning()) return;
    final history = await GatewayClient.instance.fetchHistory();
    if (history == null || history.isEmpty || _streaming ||
        messages.isNotEmpty) {
      return;
    }
    messages.addAll([
      for (final m in history)
        ChatMessage(
          role: m.role == 'user' ? ChatRole.user : ChatRole.assistant,
          content: m.content,
        ),
    ]);
    notifyListeners();
  }
}

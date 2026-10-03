import 'dart:async';
import 'dart:io' show Platform, File, Directory, FileMode;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/ai/gateway_client.dart';
import '../../data/ai/gateway_process.dart';
import '../../data/settings/api_key_entry.dart';

enum ChatRole { user, assistant }

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

  /// Selected OpenAI-compatible API key entry (id + credentials + model).
  ApiKeyEntry? selectedKey;
  String _reasoningEffort = 'medium';

  String get reasoningEffort => _reasoningEffort;

  set reasoningEffort(String value) {
    if (_reasoningEffort == value) return;
    _reasoningEffort = value;
    notifyListeners();
  }

  /// Model id actually used for the selected key: the entry's model, or the
  /// provider's default when the user left it blank.
  String? get selectedModel {
    final key = selectedKey;
    if (key == null) return null;
    final model = key.model?.trim();
    if (model != null && model.isNotEmpty) return model;
    return switch (key.provider) {
      'glm' => 'glm-4-flash',
      'qwen' => 'qwen-turbo',
      'deepseek' => 'deepseek-chat',
      _ => null,
    };
  }

  StreamSubscription<Map<String, dynamic>>? _eventSub;

  /// Diagnostic trace (appended to %TEMP%\flightstudio-chat.log). Secrets
  /// are never logged — only lengths and ids.
  void _diag(String line) {
    if (kDebugMode) debugPrint('[chat] $line');
    try {
      final f = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'flightstudio-chat.log',
      );
      f.writeAsStringSync(
        '${DateTime.now().toIso8601String()} $line\n',
        mode: FileMode.append,
      );
    } on Exception {
      // Best-effort diagnostics.
    }
  }

  void selectKey(ApiKeyEntry? key) {
    if (selectedKey?.id == key?.id) return;
    selectedKey = key;
    _persistSelection();
    notifyListeners();
  }

  // ── Selection persistence (survives app restarts) ────────────────────────

  static const _selectedKeyPref = 'chat.selectedKeyId';
  static const _reasoningPref = 'chat.reasoningEffort';
  bool _restoreAttempted = false;

  Future<void> _persistSelection() async {
    try {
      final prefs = SharedPreferencesAsync();
      await prefs.setString(_selectedKeyPref, selectedKey?.id ?? '');
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
        if (selectedKey != null) notifyListeners();
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
    final model = selectedModel;
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
            notifyListeners();
          case 'error':
            final message = event['message'] as String? ?? 'Unknown error';
            if (messages.isNotEmpty) {
              messages.last
                ..done = true
                ..content = message;
            }
            _streaming = false;
            notifyListeners();
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

  /// Aborts the running turn via the gateway's stop endpoint, keeping
  /// whatever text already streamed in.
  void stop() {
    if (!_streaming) return;
    _streaming = false;
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
}

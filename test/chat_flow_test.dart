// Chat session tests: the state machine without UI dependency.
//
// In a test environment (FLUTTER_TEST) the gateway HTTP call is skipped and
// ChatSession completes each turn immediately.

import 'package:flight_studio/ui/chat/chat_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ChatSessionManager manager;

  setUp(() {
    manager = ChatSessionManager.instance;
    manager.resetForTest();
  });

  ChatSession newSession() =>
      manager.sessionByKey(manager.newChat())!;

  test('send appends user + assistant messages and completes in test env', () {
    final s = newSession();
    s.send('飞往 ZBAA');

    expect(s.messages.length, 2);
    expect(s.messages[0].role, ChatRole.user);
    expect(s.messages[0].content, '飞往 ZBAA');
    expect(s.messages[1].role, ChatRole.assistant);
    expect(s.isStreaming, isFalse);
    expect(s.messages[1].done, isTrue);
  });

  test('stop marks streaming as false', () {
    final s = newSession();
    s.send('test');
    s.stop();
    expect(s.isStreaming, isFalse);
  });

  test('resetForTest clears all sessions and conversations', () {
    final s = newSession();
    s.send('hello');
    s.resetForTest();
    expect(s.messages, isEmpty);
    manager.resetForTest();
    expect(manager.conversations, isEmpty);
    expect(manager.sessionByKey(manager.newChat()), isNotNull);
  });

  test('empty text is ignored', () {
    final s = newSession();
    s.send('  ');
    expect(s.messages, isEmpty);
  });

  test('openConversation keys are stable and bind the conversation id', () {
    final k1 = manager.openConversation('conv-1');
    final k2 = manager.openConversation('conv-1');
    expect(k1, k2);
    expect(manager.sessionByKey(k1)!.conversationId, 'conv-1');
  });

  test('conversation_renamed updates the list and title lookup', () {
    manager.onConversationBound(
      ChatSession()..conversationId = 'conv-9',
    );
    expect(manager.titleOf('conv-9'), isNull);

    manager.dispatchTestEvent({
      'event': 'conversation_renamed',
      'conversationId': 'conv-9',
      'title': '北京进近',
    });
    expect(manager.titleOf('conv-9'), '北京进近');
  });

  test('approval requests embed in the transcript and collapse when answered',
      () {
    final s = newSession();
    s.send('hello'); // user + assistant placeholder (test env: instant).

    manager.streamingSession = s;
    manager.dispatchTestEvent({
      'event': 'approval_request',
      'id': 'approval_1',
      'tool': 'render_map',
      'input': {'lat': 40.0},
    });
    expect(s.pendingApproval?.id, 'approval_1');
    expect(
      s.messages.where((m) => m.role == ChatRole.approval),
      hasLength(1),
    );

    // User answers — the row collapses IMMEDIATELY (optimistic local
    // resolve) and the pending card clears.
    s.answerApproval(true);
    expect(s.pendingApproval, isNull);
    final row = s.messages.firstWhere((m) => m.role == ChatRole.approval);
    expect(row.approvalResolved, isTrue);
    expect(row.approvalApproved, isTrue);

    // The SSE confirmation is idempotent.
    manager.dispatchTestEvent({
      'event': 'approval_resolved',
      'id': 'approval_1',
      'approved': true,
    });
    expect(s.pendingApproval, isNull);
    expect(row.approvalResolved, isTrue);

    // Permission rows never leak into exports: their content stays empty
    // and the export filter (approval == null) is exercised implicitly by
    // the row's own invariants above.
    expect(
      s.messages.where((m) => m.approval != null).map((m) => m.content),
      everyElement(''),
    );
  });

  test('approval cards insert INLINE at the tool-call position mid-turn',
      () {
    final s = newSession();
    // Simulate a live streaming turn (send() short-circuits in tests):
    // user message + one not-yet-done assistant bubble with text.
    s.messages.add(ChatMessage(role: ChatRole.user, content: 'hello'));
    s.messages.add(
      ChatMessage(role: ChatRole.assistant, content: '正在查询', done: false),
    );
    manager.streamingSession = s;

    manager.dispatchTestEvent({
      'event': 'approval_request',
      'id': 'approval_2',
      'tool': 'weather_read',
      'input': {'icao': 'ZBAA'},
    });

    // [user, assistant('正在查询'), card, assistant('')] — the card sits
    // where the tool was requested and the reply continues in a NEW
    // bubble below it.
    expect(s.messages.length, 4);
    expect(s.messages[1].content, '正在查询');
    expect(s.messages[2].role, ChatRole.approval);
    expect(s.messages[3].role, ChatRole.assistant);
    expect(s.messages[3].content, '');

    // Subsequent deltas stream into the post-card bubble, never the
    // pre-card one.
    manager.dispatchTestEvent({'event': 'delta', 'content': ' 后续'});
    expect(s.messages[1].content, '正在查询');
    expect(s.messages[3].content, ' 后续');

    // Turn end keeps both segments as-is (full text must not overwrite
    // the split bubbles) and marks everything done.
    manager.dispatchTestEvent({
      'event': 'turn_done',
      'content': '正在查询 后续',
    });
    expect(s.messages.length, 4);
    expect(s.messages[1].content, '正在查询');
    expect(s.messages[3].content, ' 后续');
    expect(s.messages[3].done, isTrue);
    expect(s.isStreaming, isFalse);
  });

  test('auto-allowed tool calls record a resolved inline card', () {
    final s = newSession();
    s.messages.add(ChatMessage(role: ChatRole.user, content: 'hi'));
    s.messages.add(
      ChatMessage(role: ChatRole.assistant, content: '前段', done: false),
    );
    manager.streamingSession = s;

    manager.dispatchTestEvent({
      'event': 'approval_auto',
      'id': 'auto_1',
      'tool': 'mcp__flightstudio-core__weather_read',
      'input': {'icao': 'ZBAA'},
    });

    // Nothing to answer — the card arrives already resolved.
    expect(s.pendingApproval, isNull);
    expect(s.messages.length, 4);
    final row = s.messages[2];
    expect(row.role, ChatRole.approval);
    expect(row.approvalResolved, isTrue);
    expect(row.approvalApproved, isTrue);
    expect(row.approval!.autoAllowed, isTrue);
    expect(row.approval!.tool, 'mcp__flightstudio-core__weather_read');

    // The reply continues below the recorded card.
    manager.dispatchTestEvent({'event': 'delta', 'content': ' 后段'});
    expect(s.messages[3].content, ' 后段');
  });

  test('auto-denied tool calls record a denied inline card', () {
    final s = newSession();
    s.messages.add(ChatMessage(role: ChatRole.user, content: 'hi'));
    s.messages.add(
      ChatMessage(role: ChatRole.assistant, content: '前段', done: false),
    );
    manager.streamingSession = s;

    manager.dispatchTestEvent({
      'event': 'approval_auto',
      'id': 'auto_9',
      'tool': 'mcp__flightstudio-core__send_sim_command',
      'input': {'cmd': 'pause'},
      'denied': true,
    });

    expect(s.pendingApproval, isNull);
    final row = s.messages.firstWhere((m) => m.role == ChatRole.approval);
    expect(row.approvalResolved, isTrue);
    expect(row.approvalApproved, isFalse);
    expect(row.approval!.autoDenied, isTrue);
    expect(row.approval!.autoAllowed, isFalse);
  });

  test('turn end drops trailing empty bubbles left after a card', () {
    final s = newSession();
    s.messages.add(ChatMessage(role: ChatRole.user, content: 'hi'));
    s.messages.add(
      ChatMessage(role: ChatRole.assistant, content: '前段', done: false),
    );
    manager.streamingSession = s;
    manager.dispatchTestEvent({
      'event': 'approval_auto',
      'id': 'auto_2',
      'tool': 'charts_read',
      'input': {},
    });
    // No text streamed after the tool → [user, A('前段'), card, A('')].
    manager.dispatchTestEvent({'event': 'turn_done', 'content': '前段'});
    // The empty post-card bubble is dropped; the card keeps its position.
    expect(s.messages.length, 3);
    expect(s.messages[1].content, '前段');
    expect(s.messages[2].role, ChatRole.approval);
    // The single streamed bubble is not overwritten by the full text
    // (it is identical here) and stays done.
    expect(s.messages[1].done, isTrue);
  });
}

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
}

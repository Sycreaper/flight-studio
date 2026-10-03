// Chat session tests: the state machine without UI dependency.
//
// In a test environment (FLUTTER_TEST) the gateway HTTP call is skipped and
// ChatSession completes each turn immediately.

import 'package:flight_studio/ui/chat/chat_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    ChatSession.instance.resetForTest();
  });

  test('send appends user + assistant messages and completes in test env', () {
    ChatSession.instance.send('飞往 ZBAA');

    final s = ChatSession.instance;
    expect(s.messages.length, 2);
    expect(s.messages[0].role, ChatRole.user);
    expect(s.messages[0].content, '飞往 ZBAA');
    expect(s.messages[1].role, ChatRole.assistant);
    expect(s.isStreaming, isFalse);
    expect(s.messages[1].done, isTrue);
  });

  test('stop marks streaming as false', () {
    final s = ChatSession.instance;
    s.send('test');
    s.stop();
    expect(s.isStreaming, isFalse);
  });

  test('resetForTest clears all messages', () {
    ChatSession.instance.send('hello');
    ChatSession.instance.resetForTest();
    expect(ChatSession.instance.messages, isEmpty);
  });

  test('empty text is ignored', () {
    ChatSession.instance.send('  ');
    expect(ChatSession.instance.messages, isEmpty);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:flight_studio/ui/chat/chat_session.dart';

/// History hydration: tool-call rows from the official Letta history
/// become resolved permission cards in the neutral ended state (no
/// outcome restore — the backend history carries no approval records);
/// text rows become regular bubbles.
void main() {
  test('tool-call rows become neutral ended cards', () {
    final restored = ChatSession.messageFromHistoryRow(
      const (
        role: 'tool_call',
        content: '',
        tool: 'mcp__flightstudio-core__get_airport_data',
        input: {'icao': 'ZSPD'},
      ),
      id: 'hist_0',
    );
    expect(restored, isNotNull);
    expect(restored!.role, ChatRole.approval);
    expect(restored.approvalResolved, isTrue);
    expect(restored.approvalOutcomeKnown, isFalse);
    expect(restored.approval!.tool, 'mcp__flightstudio-core__get_airport_data');
    expect(restored.approval!.input['icao'], 'ZSPD');

    final second = ChatSession.messageFromHistoryRow(
      const (
        role: 'tool_call',
        content: '',
        tool: 'send_sim_command',
        input: {'command': 'pause'},
      ),
      id: 'hist_1',
    );
    expect(second!.approvalOutcomeKnown, isFalse);
  });

  test('text rows map to bubbles; empty rows drop', () {
    final user = ChatSession.messageFromHistoryRow(
      const (
        role: 'user',
        content: 'ZSPD 天气',
        tool: null,
        input: null,
      ),
      id: 'hist_2',
    );
    expect(user!.role, ChatRole.user);
    expect(user.content, 'ZSPD 天气');

    final empty = ChatSession.messageFromHistoryRow(
      const (
        role: 'assistant',
        content: '  ',
        tool: null,
        input: null,
      ),
      id: 'hist_3',
    );
    expect(empty, isNull);
  });
}

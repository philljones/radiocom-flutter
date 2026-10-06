import 'package:cuacfm/utils/home_greeting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selects greetings at local time boundaries', () {
    final expectations = {
      '00:00': 'welcome_msg_4',
      '04:59': 'welcome_msg_4',
      '05:00': 'welcome_msg_1',
      '06:00': 'welcome_msg_1',
      '12:59': 'welcome_msg_1',
      '13:00': 'welcome_msg_2',
      '20:59': 'welcome_msg_2',
      '21:00': 'welcome_msg_3',
      '22:59': 'welcome_msg_3',
      '23:00': 'welcome_msg_4',
      '23:59': 'welcome_msg_4',
    };
    for (final entry in expectations.entries) {
      final time = DateTime.parse('2026-10-06T${entry.key}:00');
      expect(homeGreetingKey(time), entry.value, reason: entry.key);
    }
  });
}

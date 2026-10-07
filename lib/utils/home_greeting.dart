/// Selects the greeting using the listener's local time.
String homeGreetingKey(DateTime localTime) {
  final hour = localTime.hour;
  if (hour < 5 || hour >= 23) return 'welcome_msg_4';
  if (hour < 12) return 'welcome_msg_1';
  if (hour < 18) return 'welcome_msg_2';
  return 'welcome_msg_3';
}

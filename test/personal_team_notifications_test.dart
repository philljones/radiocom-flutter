import 'package:cuacfm/utils/notification_subscription_contract.dart';
import 'package:cuacfm/utils/push_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('Personal Team iOS does not invoke Firebase or store subscriptions', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(pushNotificationsEnabled, isFalse);
    final subscriptions = NotificationSubscription();
    subscriptions.getToken();
    await subscriptions.subscribeToTopic('test');
    await subscriptions.unsubscribeFromTopic('test');
    expect(await subscriptions.isSubscribed('test'), isFalse);
  });

  test('Android keeps push enabled', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(pushNotificationsEnabled, isTrue);
  });
}

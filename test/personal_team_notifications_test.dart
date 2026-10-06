import 'package:cuacfm/utils/push_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('paid-account iPhone builds support push', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(pushNotificationsEnabled, isTrue);
  });

  test('Android keeps push enabled', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(pushNotificationsEnabled, isTrue);
  });

  test('denied or undecided permissions cannot enable alerts', () {
    expect(notificationPermissionGranted(AuthorizationStatus.denied), isFalse);
    expect(notificationPermissionGranted(AuthorizationStatus.notDetermined),
        isFalse);
    expect(
        notificationPermissionGranted(AuthorizationStatus.authorized), isTrue);
    expect(
        notificationPermissionGranted(AuthorizationStatus.provisional), isTrue);
  });
}

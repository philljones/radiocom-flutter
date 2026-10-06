import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

bool get pushNotificationsEnabled =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);

bool notificationPermissionGranted(AuthorizationStatus status) =>
    status == AuthorizationStatus.authorized ||
    status == AuthorizationStatus.provisional;

/// Called only when the listener explicitly enables alerts.
Future<bool> requestPushPermission({FirebaseMessaging? messaging}) async {
  if (!pushNotificationsEnabled) return false;
  final client = messaging ?? FirebaseMessaging.instance;
  final settings = await client.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  return notificationPermissionGranted(settings.authorizationStatus);
}

/// Apple must have registered the device before Firebase topic/token calls.
Future<bool> pushDeviceReady(FirebaseMessaging messaging) async {
  final settings = await messaging.getNotificationSettings();
  if (!notificationPermissionGranted(settings.authorizationStatus))
    return false;
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    for (var attempt = 0; attempt < 10; attempt++) {
      if (await messaging.getAPNSToken() != null) return true;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return false;
  }
  return true;
}

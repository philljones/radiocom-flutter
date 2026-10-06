import 'package:flutter/foundation.dart' as Foundation;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cuacfm/utils/push_notifications.dart';

abstract class NotificationSubscriptionContract {
  Future<void> subscribeToTopic(String channelName);
  Future<void> unsubscribeFromTopic(String channelName);
  Future<bool> isSubscribed(String channelName);
  void getToken();
  void setScreen(String name);
}

class NotificationSubscription implements NotificationSubscriptionContract {
  NotificationSubscription();

  @override
  void getToken() {
    if (!pushNotificationsEnabled) return;
    _refreshToken();
  }

  Future<void> _refreshToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      if (!await pushDeviceReady(messaging)) return;
      await messaging.getToken();
    } catch (error) {
      if (Foundation.kDebugMode)
        Foundation.debugPrint('Push registration unavailable: $error');
    }
  }

  @override
  Future<void> subscribeToTopic(String channelName) async {
    if (!pushNotificationsEnabled) return;
    final messaging = FirebaseMessaging.instance;
    if (!await requestPushPermission(messaging: messaging)) {
      throw StateError(
          'Notifications are disabled. Enable them in your device settings.');
    }
    if (!await pushDeviceReady(messaging)) {
      throw StateError(
          'Notifications are not ready yet. Please try again shortly.');
    }
    final tag = _sanitizeTag(channelName);
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notifications_paused') ?? false)) {
      await messaging.subscribeToTopic(tag);
    }
    await prefs.setBool('notif_$tag', true);
  }

  @override
  Future<void> unsubscribeFromTopic(String channelName) async {
    if (!pushNotificationsEnabled) return;
    final tag = _sanitizeTag(channelName);
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notifications_paused') ?? false)) {
      await FirebaseMessaging.instance.unsubscribeFromTopic(tag);
    }
    await prefs.setBool('notif_$tag', false);
  }

  @override
  Future<bool> isSubscribed(String channelName) async {
    if (!pushNotificationsEnabled) return false;
    final tag = _sanitizeTag(channelName);
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notif_$tag') ?? false;
  }

  @override
  void setScreen(String name) {
    if (Foundation.kDebugMode) {
      print('Screen: $name');
    }
  }

  String _sanitizeTag(String input) {
    final sanitized = input.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    return sanitized.substring(0, sanitized.length.clamp(0, 64));
  }
}

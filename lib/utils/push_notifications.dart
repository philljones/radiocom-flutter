import 'package:flutter/foundation.dart';

// Temporary Personal Team build: restore alongside the iOS push entitlement.
bool get pushNotificationsEnabled =>
    kIsWeb || defaultTargetPlatform != TargetPlatform.iOS;

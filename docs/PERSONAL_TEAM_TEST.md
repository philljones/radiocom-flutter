# Historical Personal Team setup

The temporary free-account push restriction has been removed now that Aber Radio
uses a paid Apple Developer account. The app requests notification permission
only when the listener chooses Enable notifications or turns on a programme alert.

Before installing or distributing a push-enabled build:

- Enable Push Notifications for App ID `uk.co.abergavennyradio.app` on team `L2QV7RR6D7`.
- Register that exact iOS bundle ID in Firebase project `abergavenny-radio` and
  replace `ios/Runner/GoogleService-Info.plist` with its downloaded configuration.
- Upload an Apple APNs authentication key to that Firebase iOS app, including its
  key ID and the Apple team ID. Configure the environments needed for device
  development and TestFlight delivery.
- Refresh signing profiles. The exported app must have the APNs entitlement
  appropriate to its distribution environment.

The existing Firebase configuration still identifies `org.cuacfm.radio.coruna`;
that must be replaced before testing push delivery.

Test permission acceptance and denial, programme subscriptions, pausing alerts,
foreground/background delivery, and opening an episode from a notification.
Do not treat a successful build as confirmation of push delivery.

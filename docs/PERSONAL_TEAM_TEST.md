# Temporary Personal Team iPhone test

Branch: `codex/personal-team-no-push`.

This build disables iOS push notifications so a free Apple Personal Team can
sign the app. The push entitlement and remote-notification background mode are
removed; audio background mode remains. Firebase Messaging auto-initialization
is disabled in Info.plist, and iOS permission, token, message, and topic calls
are skipped. Android messaging remains enabled.

The existing local Xcode edits select Phillip's Personal Team and the Debug
bundle ID `uk.co.abergavennyradio.app`. The baseline Firebase configuration is
still for the original CUAC bundle ID. Register the final bundle ID in Firebase
and download a matching configuration before restoring messaging.

To restore push with paid signing, restore the `aps-environment` entitlement,
the `remote-notification` background mode, and Firebase Messaging auto-init;
then re-enable iOS in `lib/utils/push_notifications.dart` together. Revisit the
Personal Team regression test when doing so.

On the physical phone, start the stream, return to Home, and lock the screen.
Verify audio continues and test the lock-screen pause/play controls. These
checks require observation on the phone; a successful build alone does not
verify them.

# Radiocom baseline

Original source: fbc01003f11e23d996bf71e520ab69c10dd614d4.

Flutter 3.44.1, Dart 3.12.1, Xcode 27.0 on Apple Silicon.
Source analysis passes; all 436 existing tests pass.
The unchanged app builds for the arm64 iOS simulator. iOS 27 rejects its legacy application lifecycle on launch; UIScene migration is the next compatibility change.

Firebase project: abergavenny-radio, Spark plan. Baseline Apple app uses the original bundle ID org.cuacfm.radio.coruna. Supply the ignored ios/Runner/GoogleService-Info.plist locally. Do not commit it.

The dependency locks capture the versions resolved for this build. Upstream did not track a Dart lockfile. No branding or Dart app source has changed.

## Build on this Mac

```sh
export XDG_CONFIG_HOME=/Users/philjones/Projects/abergavenny-radio/tool-config
export PUB_CACHE=/Users/philjones/Projects/abergavenny-radio/pub-cache
export FLUTTER_SUPPRESS_ANALYTICS=true
../flutter-sdk/bin/flutter pub get
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO CONFIGURATION_BUILD_DIR="$PWD/build/ios/iphonesimulator"
```

Use Xcode's default Swift package checkout location: the existing Crashlytics script expects it. Explicit arm64 avoids Flutter's multi-architecture validation failure with this Xcode version.

## iOS 27 compatibility follow-up

The separate codex/ios27-scene-lifecycle branch adopts FlutterSceneDelegate in Info.plist and registers plugins through FlutterImplicitEngineDelegate. Guidance: https://docs.flutter.dev/release/breaking-changes/uiscenedelegate

Validation: Xcode simulator build succeeded; installation and launch succeeded on the Radiocom Baseline iPhone 17 simulator. The process remained running and the Dart VM service started. Visual flows, streaming, background audio and push delivery have not yet been verified. The unsigned simulator reports a missing aps-environment entitlement.

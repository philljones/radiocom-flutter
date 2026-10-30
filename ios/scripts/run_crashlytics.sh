#!/bin/sh
set -eu

# Flutter passes its own -clonedSourcePackagesDirPath to xcodebuild. Prefer that
# checkout; retain Xcode's default location for builds opened directly in Xcode.
flutter_build_dir=${FLUTTER_BUILD_DIR:-build}
case "$flutter_build_dir" in
  /*) ;;
  *) flutter_build_dir="$SRCROOT/../$flutter_build_dir" ;;
esac

for crashlytics_run in \
  "$flutter_build_dir/ios/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run" \
  "${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
do
  if [ -x "$crashlytics_run" ]; then
    exec "$crashlytics_run" "$@"
  fi
done

printf '%s\n' 'error: Firebase Crashlytics build script not found. Resolve Swift packages before building.' >&2
exit 1

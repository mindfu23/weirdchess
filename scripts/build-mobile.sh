#!/usr/bin/env bash
# build-mobile.sh — build the Android bundle and/or iOS archive for release.
#
# WHY THIS SCRIPT EXISTS
# `flutter build appbundle --release` on its own produces an app that looks
# fine and fails every commentary call with a 403. APP_SECRET_TOKEN is baked in
# at compile time via --dart-define; if it is missing, String.fromEnvironment
# silently returns "", no X-App-Token header is sent, and the Netlify function
# rejects the request. Nothing about the build warns you, and you find out from
# a store review.
#
# So this script REFUSES to build without the token rather than producing a
# quietly broken artifact.
#
# Usage:
#   export APP_SECRET_TOKEN=...        # from the Netlify dashboard (weirdchess site)
#   bash scripts/build-mobile.sh android
#   bash scripts/build-mobile.sh ios
#   bash scripts/build-mobile.sh both

set -euo pipefail

TARGET="${1:-both}"

if [ -z "${APP_SECRET_TOKEN:-}" ]; then
  cat >&2 <<'MSG'
ERROR: APP_SECRET_TOKEN is not set.

Building without it produces an app that starts normally and returns
"API error: 403" on every commentary request, because the X-App-Token header
the Netlify function requires is never sent.

Get the value from: Netlify → weirdchess → Site configuration →
Environment variables → APP_SECRET_TOKEN, then:

    export APP_SECRET_TOKEN='...'
    bash scripts/build-mobile.sh <android|ios|both>
MSG
  exit 1
fi

# Android needs JDK 21; the system default here is 17. Android Studio ships one.
JBR="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
if [ -d "$JBR" ]; then
  export JAVA_HOME="$JBR"
fi

echo "▸ Flutter version"
flutter --version | head -1
echo "▸ App version: $(grep '^version:' pubspec.yaml | awk '{print $2}')"

echo "▸ Verifying (analyze + tests) before building a release artifact"
# --no-fatal-infos: the repo carries a few pre-existing info-level lints
# (deprecated Radio groupValue, prefer_is_empty). Warnings and errors still fail.
flutter analyze --no-fatal-infos
flutter test

DEFINE=(--dart-define=APP_SECRET_TOKEN="$APP_SECRET_TOKEN")

if [ "$TARGET" = "android" ] || [ "$TARGET" = "both" ]; then
  echo "▸ Building Android app bundle"
  flutter build appbundle --release "${DEFINE[@]}"

  AAB=build/app/outputs/bundle/release/app-release.aab
  echo "▸ Verifying the token was actually baked into $AAB"
  python3 - "$AAB" <<'PY'
import re, sys, zipfile
aab = sys.argv[1]
found = 0
with zipfile.ZipFile(aab) as z:
    for nm in z.namelist():
        if nm.endswith('libapp.so'):
            found += len(set(re.findall(rb'\b[0-9a-f]{32,64}\b', z.read(nm))))
if not found:
    sys.exit(
        "FAILED: no token-shaped constant found in the bundle. The build did not\n"
        "bake APP_SECRET_TOKEN — do not upload this artifact."
    )
print(f"  OK — token-shaped constant present ({found} candidate(s))")
PY
  echo "▸ Android bundle ready: $AAB"
fi

if [ "$TARGET" = "ios" ] || [ "$TARGET" = "both" ]; then
  echo "▸ Building iOS archive"
  flutter build ipa --release "${DEFINE[@]}"
  echo "▸ iOS archive ready: build/ios/archive/Runner.xcarchive"
  echo "  Upload with Xcode Organizer, or:"
  echo "    xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios -u <apple-id>"
fi

echo "▸ Done. Remember Play consumes a versionCode on ANY track — bump pubspec"
echo "  version before the next upload."

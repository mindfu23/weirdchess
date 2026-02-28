#!/usr/bin/env bash
# build-web.sh — Install Flutter (cached) and build the web app for Netlify.
#
# Environment variables read:
#   APP_SECRET_TOKEN  – baked into the web build via --dart-define
#
# Netlify caches /opt/buildhome/cache/ between builds, so the Flutter SDK
# is only downloaded once.

set -euo pipefail

FLUTTER_CACHE="${NETLIFY_BUILD_BASE:-/opt/buildhome}/cache/flutter"

# ── Install or update Flutter ────────────────────────────────────────────────
if [ -d "$FLUTTER_CACHE/bin" ]; then
  echo "▸ Using cached Flutter SDK"
  export PATH="$FLUTTER_CACHE/bin:$PATH"
  flutter upgrade --force
else
  echo "▸ Downloading Flutter SDK (first build — this takes a few minutes)"
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_CACHE"
  export PATH="$FLUTTER_CACHE/bin:$PATH"
fi

flutter --version

# ── Build ────────────────────────────────────────────────────────────────────
echo "▸ Getting dependencies"
flutter pub get

echo "▸ Building web release"
flutter build web --release \
  --dart-define=APP_SECRET_TOKEN="${APP_SECRET_TOKEN:-}"

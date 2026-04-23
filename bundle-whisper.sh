#!/usr/bin/env bash
# Bundle statically-linked whisper-cli into Handsfree.app.
# No external dylibs, no ggml backend plugins needed — everything compiled in.
# Only depends on macOS system frameworks (Accelerate, Metal, Foundation).
#
# Source: built from github.com/ggerganov/whisper.cpp by build-static-whisper.sh.
# Run after xcodebuild, before DMG packaging.

set -euo pipefail

APP="${1:-}"
if [ -z "$APP" ] || [ ! -d "$APP" ]; then
  echo "Usage: $0 <path/to/Handsfree.app>"
  exit 1
fi

# Static binary lives next to this script (checked into the repo).
SRC="$(cd "$(dirname "$0")" && pwd)/vendor/whisper-cli-static"
if [ ! -f "$SRC" ]; then
  echo "Missing static whisper-cli at $SRC"
  echo "Build it first with:  ./build-static-whisper.sh"
  exit 1
fi

RESOURCES="$APP/Contents/Resources"
mkdir -p "$RESOURCES"

# Clean up any previous bundle artifacts from older non-static approach.
rm -rf "$APP/Contents/Frameworks/libwhisper.1.dylib" \
       "$APP/Contents/Frameworks/libggml.0.dylib" \
       "$APP/Contents/Frameworks/libggml-base.0.dylib" \
       "$APP/Contents/Frameworks/libomp.dylib" \
       "$RESOURCES/ggml-backends"

cp -f "$SRC" "$RESOURCES/whisper-cli"
chmod +x "$RESOURCES/whisper-cli"

codesign --force --sign - "$RESOURCES/whisper-cli"
codesign --force --deep --sign - "$APP"

echo "Bundled static whisper-cli ($(du -h "$RESOURCES/whisper-cli" | awk '{print $1}'))"
echo ""
echo "Dependencies (system frameworks only):"
otool -L "$RESOURCES/whisper-cli" | grep -v ":$" | sed 's/^/  /'

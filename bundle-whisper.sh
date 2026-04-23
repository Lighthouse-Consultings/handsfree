#!/usr/bin/env bash
# Bundle whisper-cli + its dylibs into Handsfree.app so end-users don't need brew.
# Run after xcodebuild, before DMG packaging.
# Requires: whisper-cpp installed locally via homebrew.

set -euo pipefail

APP="${1:-}"
if [ -z "$APP" ] || [ ! -d "$APP" ]; then
  echo "Usage: $0 <path/to/Handsfree.app>"
  exit 1
fi

RESOURCES="$APP/Contents/Resources"
FRAMEWORKS="$APP/Contents/Frameworks"
mkdir -p "$RESOURCES" "$FRAMEWORKS"

# Source paths (current brew install — check if formula version changes)
SRC_CLI="/opt/homebrew/bin/whisper-cli"
SRC_WHISPER="/opt/homebrew/lib/libwhisper.1.dylib"
SRC_GGML="/opt/homebrew/opt/ggml/lib/libggml.0.dylib"
SRC_GGML_BASE="/opt/homebrew/opt/ggml/lib/libggml-base.0.dylib"

for f in "$SRC_CLI" "$SRC_WHISPER" "$SRC_GGML" "$SRC_GGML_BASE"; do
  [ -f "$(readlink -f "$f" 2>/dev/null || realpath "$f")" ] || { echo "Missing: $f"; exit 1; }
done

echo "[1/5] Copying binary + dylibs + ggml backends..."
cp -f "$SRC_CLI"       "$RESOURCES/whisper-cli"
cp -fL "$SRC_WHISPER"   "$FRAMEWORKS/libwhisper.1.dylib"
cp -fL "$SRC_GGML"      "$FRAMEWORKS/libggml.0.dylib"
cp -fL "$SRC_GGML_BASE" "$FRAMEWORKS/libggml-base.0.dylib"
chmod +w "$RESOURCES/whisper-cli" "$FRAMEWORKS"/*.dylib

# ggml dynamically loads CPU/BLAS/Metal backends from <libexec>/libggml-*.so
# at runtime via GGML_BACKEND_PATH env var (set in LocalWhisperClient.swift).
BACKENDS_SRC=$(ls -d /opt/homebrew/Cellar/ggml/*/libexec 2>/dev/null | head -1)
BACKENDS_DST="$RESOURCES/ggml-backends"
if [ -n "$BACKENDS_SRC" ] && [ -d "$BACKENDS_SRC" ]; then
  mkdir -p "$BACKENDS_DST"
  cp -f "$BACKENDS_SRC"/*.so "$BACKENDS_DST/"
  chmod +w "$BACKENDS_DST"/*.so
  echo "      Backends from: $BACKENDS_SRC"
else
  echo "      WARN: ggml libexec dir not found — Metal/BLAS acceleration won't work"
fi

echo "[2/5] Rewriting dylib IDs to @rpath..."
install_name_tool -id "@rpath/libwhisper.1.dylib"   "$FRAMEWORKS/libwhisper.1.dylib"
install_name_tool -id "@rpath/libggml.0.dylib"      "$FRAMEWORKS/libggml.0.dylib"
install_name_tool -id "@rpath/libggml-base.0.dylib" "$FRAMEWORKS/libggml-base.0.dylib"

echo "[3/5] Rewriting cross-references inside dylibs..."
# libwhisper references absolute paths to libggml — point to @rpath
install_name_tool -change "/opt/homebrew/opt/whisper-cpp/lib/libwhisper.1.dylib" "@rpath/libwhisper.1.dylib"   "$FRAMEWORKS/libwhisper.1.dylib"
install_name_tool -change "/opt/homebrew/opt/ggml/lib/libggml.0.dylib"           "@rpath/libggml.0.dylib"      "$FRAMEWORKS/libwhisper.1.dylib"
install_name_tool -change "/opt/homebrew/opt/ggml/lib/libggml-base.0.dylib"      "@rpath/libggml-base.0.dylib" "$FRAMEWORKS/libwhisper.1.dylib"
# libggml -> libggml-base already uses @rpath, confirm
install_name_tool -change "@rpath/libggml-base.0.dylib" "@rpath/libggml-base.0.dylib" "$FRAMEWORKS/libggml.0.dylib" 2>/dev/null || true

echo "[4/5] Rewriting whisper-cli references + rpath..."
install_name_tool -change "/opt/homebrew/opt/ggml/lib/libggml.0.dylib"      "@rpath/libggml.0.dylib"      "$RESOURCES/whisper-cli"
install_name_tool -change "/opt/homebrew/opt/ggml/lib/libggml-base.0.dylib" "@rpath/libggml-base.0.dylib" "$RESOURCES/whisper-cli"

# Remove old rpath (points to brew Cellar) if present
install_name_tool -delete_rpath "@loader_path/../lib" "$RESOURCES/whisper-cli" 2>/dev/null || true
# Add rpath pointing to our bundled Frameworks: Resources/whisper-cli -> ../Frameworks/
install_name_tool -add_rpath "@executable_path/../Frameworks" "$RESOURCES/whisper-cli"

# Bundle libomp (CPU backends depend on it)
OMP_SRC="/opt/homebrew/opt/libomp/lib/libomp.dylib"
if [ -f "$OMP_SRC" ]; then
  cp -fL "$OMP_SRC" "$FRAMEWORKS/libomp.dylib"
  chmod +w "$FRAMEWORKS/libomp.dylib"
  install_name_tool -id "@rpath/libomp.dylib" "$FRAMEWORKS/libomp.dylib" 2>/dev/null || true
fi

# Rewrite backend .so references: libomp absolute path -> @rpath
if [ -d "$BACKENDS_DST" ]; then
  for so in "$BACKENDS_DST"/*.so; do
    install_name_tool -change "/opt/homebrew/opt/libomp/lib/libomp.dylib" "@rpath/libomp.dylib" "$so" 2>/dev/null || true
    # Add rpath pointing to Frameworks so @rpath/libggml-base.0.dylib resolves
    install_name_tool -add_rpath "@loader_path/../../Frameworks" "$so" 2>/dev/null || true
  done
fi

echo "[5/5] Re-signing modified binaries..."
codesign --force --sign - "$FRAMEWORKS/libwhisper.1.dylib"
codesign --force --sign - "$FRAMEWORKS/libggml.0.dylib"
codesign --force --sign - "$FRAMEWORKS/libggml-base.0.dylib"
[ -f "$FRAMEWORKS/libomp.dylib" ] && codesign --force --sign - "$FRAMEWORKS/libomp.dylib"
codesign --force --sign - "$RESOURCES/whisper-cli"
[ -d "$BACKENDS_DST" ] && for so in "$BACKENDS_DST"/*.so; do codesign --force --sign - "$so"; done
codesign --force --deep --sign - "$APP"

echo ""
echo "Verify bundled whisper-cli:"
otool -L "$RESOURCES/whisper-cli" | sed 's/^/  /'
echo ""
echo "Done. whisper-cli and its dylibs are now inside $APP"

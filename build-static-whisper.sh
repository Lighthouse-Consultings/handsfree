#!/usr/bin/env bash
# Build a statically-linked whisper-cli with Metal + BLAS + Accelerate support.
# Outputs to vendor/whisper-cli-static (checked into repo so end users don't
# need cmake/brew/anything). Apple Silicon only (arm64).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENDOR="$SCRIPT_DIR/vendor"
BUILD_DIR="/tmp/handsfree-whisper-static"

if ! command -v cmake >/dev/null 2>&1; then
  echo "cmake required. Install: brew install cmake"
  exit 1
fi

mkdir -p "$VENDOR"
rm -rf "$BUILD_DIR"
git clone --depth 1 https://github.com/ggerganov/whisper.cpp.git "$BUILD_DIR"
cd "$BUILD_DIR"

cmake -B build \
  -DBUILD_SHARED_LIBS=OFF \
  -DGGML_METAL=ON \
  -DGGML_METAL_EMBED_LIBRARY=ON \
  -DGGML_ACCELERATE=ON \
  -DGGML_BLAS=ON \
  -DGGML_BACKEND_DL=OFF \
  -DWHISPER_BUILD_TESTS=OFF \
  -DWHISPER_BUILD_EXAMPLES=ON \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
  -DCMAKE_BUILD_TYPE=Release

cmake --build build --config Release -j8

cp build/bin/whisper-cli "$VENDOR/whisper-cli-static"
echo ""
echo "Built static whisper-cli:"
ls -lh "$VENDOR/whisper-cli-static"
otool -L "$VENDOR/whisper-cli-static" | grep -v ":$" | sed 's/^/  /'

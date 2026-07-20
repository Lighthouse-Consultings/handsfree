#!/usr/bin/env bash
# Build a statically-linked universal (arm64 + x86_64) whisper-cli.
# Outputs to vendor/whisper-cli-static (checked into repo so end users don't
# need cmake/brew/anything).
#
# Two separate cmake builds merged via lipo — a single fat build can't work:
#   arm64  : Metal GPU backend (the perf core on Apple Silicon) + Accelerate
#   x86_64 : CPU-only. Metal OFF (Intel Macs have no ggml-usable Metal GPU).
#            AVX2/FMA/F16C ON — safe: macOS 14 only runs on Intel Macs from
#            2018+, all of which have these. AVX512 OFF — not all supported
#            CPUs have it, and Rosetta 2 can't execute it (untestable here).
#
# Host requirement: Rosetta 2 for the x86_64 smoke test
# (softwareupdate --install-rosetta --agree-to-license).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENDOR="$SCRIPT_DIR/vendor"
BUILD_DIR="/tmp/handsfree-whisper-static"
# Pinned release tag — master drift has broken flags/builds before.
WHISPER_REF="${WHISPER_REF:-v1.9.1}"

if ! command -v cmake >/dev/null 2>&1; then
  echo "cmake required. Install: brew install cmake"
  exit 1
fi

mkdir -p "$VENDOR"
rm -rf "$BUILD_DIR"
git clone --depth 1 --branch "$WHISPER_REF" https://github.com/ggerganov/whisper.cpp.git "$BUILD_DIR"
cd "$BUILD_DIR"

COMMON_FLAGS=(
  -DBUILD_SHARED_LIBS=OFF
  -DGGML_ACCELERATE=ON
  -DGGML_BLAS=ON
  -DGGML_BACKEND_DL=OFF
  -DWHISPER_BUILD_TESTS=OFF
  -DWHISPER_BUILD_EXAMPLES=ON
  -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0
  -DCMAKE_BUILD_TYPE=Release
)

echo "=== arm64 slice (Metal) ==="
cmake -B build-arm64 \
  "${COMMON_FLAGS[@]}" \
  -DGGML_METAL=ON \
  -DGGML_METAL_EMBED_LIBRARY=ON \
  -DCMAKE_OSX_ARCHITECTURES=arm64
cmake --build build-arm64 --config Release -j8

echo "=== x86_64 slice (CPU-only, cross-compiled) ==="
cmake -B build-x86_64 \
  "${COMMON_FLAGS[@]}" \
  -DGGML_METAL=OFF \
  -DGGML_METAL_EMBED_LIBRARY=OFF \
  -DGGML_NATIVE=OFF \
  -DGGML_AVX=ON \
  -DGGML_AVX2=ON \
  -DGGML_FMA=ON \
  -DGGML_F16C=ON \
  -DGGML_AVX512=OFF \
  -DCMAKE_OSX_ARCHITECTURES=x86_64
cmake --build build-x86_64 --config Release -j8

lipo -create \
  build-arm64/bin/whisper-cli \
  build-x86_64/bin/whisper-cli \
  -output "$VENDOR/whisper-cli-static"

ARCHS_OUT="$(lipo -archs "$VENDOR/whisper-cli-static")"
if [[ "$ARCHS_OUT" != *arm64* || "$ARCHS_OUT" != *x86_64* ]]; then
  echo "FAT CHECK FAILED: got '$ARCHS_OUT', need arm64 + x86_64"
  exit 1
fi

echo "Rosetta smoke test (x86_64 slice)..."
arch -x86_64 "$VENDOR/whisper-cli-static" --help >/dev/null

echo ""
echo "Built universal static whisper-cli ($ARCHS_OUT):"
ls -lh "$VENDOR/whisper-cli-static"
otool -L "$VENDOR/whisper-cli-static" | grep -v ":$" | sed 's/^/  /'

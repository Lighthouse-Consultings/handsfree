#!/usr/bin/env bash
# Build signed + notarized DMGs from a built Handsfree.app (brand: Flinktext).
# - Reads version from project.yml (CFBundleShortVersionString)
# - Signs whisper-cli + app with Developer ID (hardened runtime), notarizes and
#   staples app and DMG. Falls back to unsigned DMG if no Developer ID cert found.
# - Volume label is the brand name "Flinktext" (visible when mounted in Finder)
# - Outputs Handsfree-vX.Y.Z.dmg (versioned archive), Flinktext.dmg (brand stable
#   filename) and Handsfree.dmg (legacy stable filename the website still links to)
#
# One-time setup for notarization (app-specific password from appleid.apple.com):
#   xcrun notarytool store-credentials lhc-notary \
#     --apple-id nico.roepnack@lighthouseconsultings.com \
#     --team-id 9K68K7DKSL --password <app-specific-password>

set -euo pipefail

APP="${1:-}"
if [ -z "$APP" ] || [ ! -d "$APP" ]; then
  echo "Usage: $0 <path/to/Handsfree.app> [output-dir]"
  echo "  output-dir defaults to ~/Desktop/Handsfree-Release"
  exit 1
fi

OUT_DIR="${2:-$HOME/Desktop/Handsfree-Release}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
KEYCHAIN_PROFILE="${KEYCHAIN_PROFILE:-lhc-notary}"

# Extract version from project.yml — single source of truth.
VERSION=$(awk -F'"' '/CFBundleShortVersionString/ {print $2; exit}' "$ROOT/project.yml")
if [ -z "$VERSION" ]; then
  echo "Failed to read CFBundleShortVersionString from project.yml"
  exit 1
fi

VOL_NAME="Flinktext"
VERSIONED_DMG="$OUT_DIR/Handsfree-v${VERSION}.dmg"
FLINKTEXT_DMG="$OUT_DIR/Flinktext.dmg"
STABLE_DMG="$OUT_DIR/Handsfree.dmg"

mkdir -p "$OUT_DIR"

# ---------------------------------------------------------------------------
# Sign + notarize the app (skipped with a warning if no Developer ID cert).
# ---------------------------------------------------------------------------
IDENTITY=$(security find-identity -v -p codesigning | awk -F'"' '/Developer ID Application/ {print $2; exit}')

if [ -n "$IDENTITY" ]; then
  echo "Signing with: $IDENTITY"

  # Nested executables first — adding whisper-cli after signing would break the seal.
  if [ -f "$APP/Contents/Resources/whisper-cli" ]; then
    codesign --force --options runtime --timestamp \
      --sign "$IDENTITY" "$APP/Contents/Resources/whisper-cli"
  fi

  codesign --force --options runtime --timestamp \
    --entitlements "$ROOT/Handsfree/Handsfree.entitlements" \
    --sign "$IDENTITY" "$APP"

  codesign --verify --deep --strict "$APP"

  echo "Notarizing app (this takes a few minutes)…"
  NOTARIZE_ZIP=$(mktemp -d)/app.zip
  ditto -c -k --keepParent "$APP" "$NOTARIZE_ZIP"
  xcrun notarytool submit "$NOTARIZE_ZIP" \
    --keychain-profile "$KEYCHAIN_PROFILE" --wait
  rm -f "$NOTARIZE_ZIP"

  xcrun stapler staple "$APP"
else
  echo "WARNING: no Developer ID Application certificate found — building UNSIGNED DMG."
fi

# ---------------------------------------------------------------------------
# Build the DMG from the (stapled) app.
# ---------------------------------------------------------------------------
# Stage app + Applications symlink in a temp dir so DMG opens with both side-by-side.
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

# Remove stale DMGs (hdiutil refuses to overwrite).
rm -f "$VERSIONED_DMG" "$FLINKTEXT_DMG" "$STABLE_DMG"

echo "Building DMG: $VOL_NAME"
hdiutil create \
  -volname "$VOL_NAME" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  -fs HFS+ \
  "$VERSIONED_DMG" >/dev/null

if [ -n "$IDENTITY" ]; then
  codesign --force --timestamp --sign "$IDENTITY" "$VERSIONED_DMG"
  echo "Notarizing DMG…"
  xcrun notarytool submit "$VERSIONED_DMG" \
    --keychain-profile "$KEYCHAIN_PROFILE" --wait
  xcrun stapler staple "$VERSIONED_DMG"
fi

# Stable filenames are real copies, not symlinks — GitHub release upload needs real
# files. Flinktext.dmg is the new brand filename; Handsfree.dmg stays so the website's
# existing releases/latest/download/Handsfree.dmg link keeps working.
cp "$VERSIONED_DMG" "$FLINKTEXT_DMG"
cp "$VERSIONED_DMG" "$STABLE_DMG"

SIZE=$(du -h "$VERSIONED_DMG" | awk '{print $1}')
echo ""
echo "Done."
echo "  $VERSIONED_DMG  ($SIZE)"
echo "  $FLINKTEXT_DMG     (copy of versioned, brand filename)"
echo "  $STABLE_DMG     (copy of versioned, legacy filename for website link)"
echo ""
echo "Volume label when mounted: \"$VOL_NAME\""
if [ -n "$IDENTITY" ]; then
  echo "Signed + notarized. Verify with: spctl -a -t open --context context:primary-signature -vv $VERSIONED_DMG"
fi

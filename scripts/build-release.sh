#!/usr/bin/env bash
#
# build-release.sh — compile Clauffee in Release, ad-hoc sign it, and package
# a distributable Clauffee.zip you can upload to a GitHub Release.
#
# No Apple Developer account needed. The resulting app is NOT notarized, so on
# first launch users must right-click Clauffee.app -> Open (documented in the
# README). Re-run this whenever you cut a new version.
#
# Usage:
#   ./scripts/build-release.sh
#
set -euo pipefail

# --- locate repo root (this script lives in scripts/) ---------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

PROJECT="Clauffee.xcodeproj"
SCHEME="Clauffee"
CONFIG="Release"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="Clauffee.app"

echo "==> Cleaning previous build output"
rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "==> Building $SCHEME ($CONFIG)"
# Manual signing with identity "-" => a real, sealed ad-hoc signature, without
# needing an Apple Developer account or Team. (Plain linker-signing would not
# seal the whole bundle and fails `codesign --verify --strict`.)
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="-" \
  DEVELOPMENT_TEAM="" \
  CODE_SIGNING_REQUIRED=YES \
  CODE_SIGNING_ALLOWED=YES \
  clean build

APP_PATH="$BUILD_DIR/Build/Products/$CONFIG/$APP_NAME"
if [[ ! -d "$APP_PATH" ]]; then
  echo "!! Build succeeded but $APP_PATH not found" >&2
  exit 1
fi

echo "==> Verifying code signature"
codesign --verify --strict --verbose=2 "$APP_PATH"

# --- read the version straight from the built app ---------------------------
VERSION="$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" \
  "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "dev")"
ZIP_PATH="$DIST_DIR/Clauffee-$VERSION.zip"

echo "==> Packaging $ZIP_PATH"
# ditto preserves macOS metadata / symlinks so the .app stays valid.
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

# --- also build a .dmg (drag-to-Applications) --------------------------------
DMG_PATH="$DIST_DIR/Clauffee-$VERSION.dmg"
echo "==> Packaging $DMG_PATH"
STAGE="$(mktemp -d)/Clauffee"
mkdir -p "$STAGE"
ditto "$APP_PATH" "$STAGE/Clauffee.app"        # keep the sealed signature
ln -s /Applications "$STAGE/Applications"       # drag target
hdiutil create -volname "Clauffee" -srcfolder "$STAGE" -ov -format UDZO "$DMG_PATH" >/dev/null
rm -rf "$(dirname "$STAGE")"

echo ""
echo "Done."
echo "  App: $APP_PATH"
echo "  Zip: $ZIP_PATH"
echo "  Dmg: $DMG_PATH"
echo ""
echo "Next: upload the zip and dmg to a GitHub Release (tag e.g. v$VERSION)."

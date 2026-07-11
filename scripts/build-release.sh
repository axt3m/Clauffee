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
# CODE_SIGN_IDENTITY="-" => ad-hoc signature (free, no Developer ID / Team).
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  clean build

APP_PATH="$BUILD_DIR/Build/Products/$CONFIG/$APP_NAME"
if [[ ! -d "$APP_PATH" ]]; then
  echo "!! Build succeeded but $APP_PATH not found" >&2
  exit 1
fi

# --- read the version straight from the built app ---------------------------
VERSION="$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" \
  "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "dev")"
ZIP_PATH="$DIST_DIR/Clauffee-$VERSION.zip"

echo "==> Packaging $ZIP_PATH"
# ditto preserves macOS metadata / symlinks so the .app stays valid.
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo ""
echo "Done."
echo "  App: $APP_PATH"
echo "  Zip: $ZIP_PATH"
echo ""
echo "Next: upload $ZIP_PATH to a GitHub Release (tag e.g. v$VERSION)."

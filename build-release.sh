#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="Lightweight"
BUNDLE="$APP_NAME.app"
DIST_DIR="dist"
DIST_BUNDLE="$DIST_DIR/$BUNDLE"
CONFIGURATION="release"
EXECUTABLE="LightweightChat"
PACKAGE_DIR="LightweightChat"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"
CLEAN=0

for arg in "$@"; do
    case "$arg" in
        --clean) CLEAN=1 ;;
        *) echo "Unknown option: $arg (usage: $0 [--clean])" >&2; exit 1 ;;
    esac
done

if [ "$CLEAN" -eq 1 ]; then
    echo "=== Cleaning ==="
    swift package --package-path "$PACKAGE_DIR" clean
    rm -rf "$DIST_DIR" "$BUNDLE"
fi

# Resolve signing identity to a hash: duplicate names in the keychain
# make `codesign --sign "Apple Development"` ambiguous.
if [ -z "$SIGNING_IDENTITY" ]; then
    SIGNING_IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null | grep -m1 'Apple Development' | awk '{print $2}')"
    if [ -z "$SIGNING_IDENTITY" ]; then
        echo "No 'Apple Development' identity found (override with SIGNING_IDENTITY=...)" >&2; exit 1
    fi
    echo "Resolved signing identity: $SIGNING_IDENTITY"
fi

echo "=== Building $APP_NAME ($CONFIGURATION) ==="

# Build
swift build -c "$CONFIGURATION" --package-path "$PACKAGE_DIR"

# Create dist bundle
mkdir -p "$DIST_DIR"
mkdir -p "$DIST_BUNDLE/Contents/MacOS"
mkdir -p "$DIST_BUNDLE/Contents/Resources"

BIN_PATH=$(swift build -c "$CONFIGURATION" --package-path "$PACKAGE_DIR" --show-bin-path)
cp "$BIN_PATH/$EXECUTABLE" "$DIST_BUNDLE/Contents/MacOS/$EXECUTABLE"
for b in "$BIN_PATH"/*.bundle; do
    [ -e "$b" ] && cp -R "$b" "$DIST_BUNDLE/Contents/Resources/"
done
cp "$PACKAGE_DIR/Resources/Info.plist" "$DIST_BUNDLE/Contents/Info.plist"
cp "$PACKAGE_DIR/Resources/AppIcon.icns" "$DIST_BUNDLE/Contents/Resources/AppIcon.icns"
cp "$PACKAGE_DIR/Resources/locy_tray.jpeg" "$DIST_BUNDLE/Contents/Resources/locy_tray.jpeg"
cp "$PACKAGE_DIR/Resources/LightweightChat.entitlements" "$DIST_BUNDLE/Contents/Resources/LightweightChat.entitlements"

# Sign with hardened runtime + timestamp (required for notarization) and entitlements.
codesign --force --options runtime --timestamp \
    --entitlements "$PACKAGE_DIR/Resources/LightweightChat.entitlements" \
    --sign "$SIGNING_IDENTITY" --identifier "org.peterc.lightweight" "$DIST_BUNDLE"

echo "=== Done: $DIST_BUNDLE ==="
echo "To run: open '$DIST_BUNDLE'"

#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$REPO_ROOT/dist"
APP_NAME="QR Code Generator"
APP_BUNDLE="$OUTPUT_DIR/$APP_NAME.app"
RELEASE_VERSION="${1:-${RELEASE_VERSION:-1.0.0}}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"
BUNDLE_ID="${BUNDLE_ID:-com.example.qrcodegenerator}"
DMG_FILENAME="$OUTPUT_DIR/QRCodeGenerator-${RELEASE_VERSION}-universal.dmg"
DMG_TEMP="$OUTPUT_DIR/QRCodeGenerator-temp.dmg"
DMG_VOLUME_NAME="QR Code Generator"
DMG_CONTENTS="$(mktemp -d "${TMPDIR:-/tmp}/qr-code-generator-dmg.XXXXXX")"
DEVICE=""

cleanup() {
    if [ -n "$DEVICE" ]; then
        hdiutil detach "$DEVICE" -quiet || true
    fi
    rm -f "$DMG_TEMP"
    rm -rf "$DMG_CONTENTS"
}
trap cleanup EXIT

[[ "$RELEASE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Release version must be Major.Minor.Patch." >&2; exit 1; }
[[ "$BUNDLE_ID" =~ ^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$ ]] || { echo "BUNDLE_ID must be a reverse-DNS identifier." >&2; exit 1; }

if [ ! -d "$APP_BUNDLE" ]; then
    echo "App bundle not found. Run scripts/build-release.sh first."
    exit 1
fi

rm -f "$DMG_FILENAME"
cp -R "$APP_BUNDLE" "$DMG_CONTENTS/"
ln -s /Applications "$DMG_CONTENTS/Applications"

hdiutil create -volname "$DMG_VOLUME_NAME" -srcfolder "$DMG_CONTENTS" -ov -format UDRW -size 50m "$DMG_TEMP"
DEVICE="$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_TEMP" | awk '/^\/dev\// { print $1; exit }')"

osascript <<EOT
tell application "Finder"
    tell disk "$DMG_VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 900, 400}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 72
        set position of item "$APP_NAME.app" of container window to {125, 150}
        set position of item "Applications" of container window to {375, 150}
        close
        open
        update without registering applications
    end tell
end tell
EOT

hdiutil detach "$DEVICE"
DEVICE=""
hdiutil convert "$DMG_TEMP" -format UDZO -imagekey zlib-level=9 -o "$DMG_FILENAME"
hdiutil verify "$DMG_FILENAME"
if [ -n "$SIGNING_IDENTITY" ]; then
    [[ "$SIGNING_IDENTITY" == Developer\ ID\ Application:* ]] || { echo "SIGNING_IDENTITY must be a Developer ID Application identity." >&2; exit 1; }
    codesign --force --sign "$SIGNING_IDENTITY" --timestamp --identifier "$BUNDLE_ID.dmg" "$DMG_FILENAME"
    codesign --verify --verbose=2 "$DMG_FILENAME"
fi
echo "DMG created: $DMG_FILENAME"

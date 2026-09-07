#!/bin/bash
set -euo pipefail
[ "$#" -eq 1 ] || { echo "Usage: $0 <notarized-dmg>" >&2; exit 1; }
DMG="$1"; DEVICE=""
cleanup() { [ -z "$DEVICE" ] || hdiutil detach "$DEVICE" -quiet || true; }; trap cleanup EXIT
hdiutil verify "$DMG"; xcrun stapler validate "$DMG"
spctl --assess --type open --context context:primary-signature -vv "$DMG"
ATTACH_OUTPUT="$(hdiutil attach -readonly -nobrowse "$DMG")"
DEVICE="$(awk '/^\/dev\// { print $1; exit }' <<< "$ATTACH_OUTPUT")"
MOUNT_POINT="$(awk -F'\t' '/^\/dev\// { print $NF; exit }' <<< "$ATTACH_OUTPUT")"
APP_BUNDLE="$MOUNT_POINT/QR Code Generator.app"
[ -d "$APP_BUNDLE" ] || { echo "Expected app bundle is missing from DMG." >&2; exit 1; }
codesign --verify --strict --deep --verbose=2 "$APP_BUNDLE"; xcrun stapler validate "$APP_BUNDLE"
spctl --assess --type execute -vv "$APP_BUNDLE"
echo "Notarized DMG and bundled app verified: $DMG"

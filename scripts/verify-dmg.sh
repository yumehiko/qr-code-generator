#!/bin/bash
set -euo pipefail
[ "$#" -eq 1 ] || { echo "Usage: $0 <notarized-dmg>" >&2; exit 1; }
DMG="$1"; DEVICE=""; MOUNT_POINT=""
cleanup() {
  [ -z "$DEVICE" ] || hdiutil detach "$DEVICE" -quiet || true
  [ -z "$MOUNT_POINT" ] || rmdir "$MOUNT_POINT" 2>/dev/null || true
}
trap cleanup EXIT
hdiutil verify "$DMG"; xcrun stapler validate "$DMG"
spctl --assess --type open --context context:primary-signature -vv "$DMG"
MOUNT_POINT="$(mktemp -d "${TMPDIR:-/tmp}/qr-code-generator-verify.XXXXXX")"
ATTACH_OUTPUT="$(hdiutil attach -readonly -nobrowse -mountpoint "$MOUNT_POINT" "$DMG")"
DEVICE="$(awk '/^\/dev\// { print $1; exit }' <<< "$ATTACH_OUTPUT")"
[ -n "$DEVICE" ] || { echo "Could not determine the attached disk device." >&2; exit 1; }
APP_BUNDLE="$MOUNT_POINT/QR Code Generator.app"
[ -d "$APP_BUNDLE" ] || { echo "Expected app bundle is missing from DMG." >&2; exit 1; }
codesign --verify --strict --deep --verbose=2 "$APP_BUNDLE"; xcrun stapler validate "$APP_BUNDLE"
spctl --assess --type execute -vv "$APP_BUNDLE"
echo "Notarized DMG and bundled app verified: $DMG"

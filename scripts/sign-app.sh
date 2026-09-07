#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_BUNDLE="$REPO_ROOT/dist/QR Code Generator.app"
ENTITLEMENTS="$REPO_ROOT/config/macos/QRCodeGenerator.entitlements"
SIGNING_IDENTITY="${SIGNING_IDENTITY:--}"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "App bundle not found. Run scripts/build-release.sh first."
    exit 1
fi

codesign --remove-signature "$APP_BUNDLE" 2>/dev/null || true
if [ "$SIGNING_IDENTITY" = "-" ]; then
    codesign --force --sign - --entitlements "$ENTITLEMENTS" --options runtime "$APP_BUNDLE"
    echo "Ad-hoc signing completed: $APP_BUNDLE"
else
    [[ "$SIGNING_IDENTITY" == Developer\ ID\ Application:* ]] || { echo "SIGNING_IDENTITY must be a Developer ID Application identity." >&2; exit 1; }
    codesign --force --sign "$SIGNING_IDENTITY" --entitlements "$ENTITLEMENTS" --options runtime --timestamp "$APP_BUNDLE"
    echo "Developer ID signing completed: $APP_BUNDLE"
fi
codesign --verify --strict --verbose=2 "$APP_BUNDLE"

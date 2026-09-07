#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_BUNDLE="$REPO_ROOT/dist/QR Code Generator.app"
ENTITLEMENTS="$REPO_ROOT/config/macos/QRCodeGenerator.entitlements"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "App bundle not found. Run scripts/build-release.sh first."
    exit 1
fi

codesign --remove-signature "$APP_BUNDLE" 2>/dev/null || true
codesign --force --deep --sign - --entitlements "$ENTITLEMENTS" --options runtime "$APP_BUNDLE"
codesign --verify --verbose "$APP_BUNDLE"
echo "Ad-hoc signing completed: $APP_BUNDLE"

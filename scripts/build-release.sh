#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$REPO_ROOT/dist"
APP_NAME="QR Code Generator"
APP_BUNDLE="$OUTPUT_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$REPO_ROOT"
mkdir -p "$OUTPUT_DIR"

echo "Building optimized release executable..."
swift build -c release \
    -Xswiftc -O \
    -Xswiftc -whole-module-optimization \
    -Xswiftc -cross-module-optimization \
    -Xswiftc -enforce-exclusivity=checked

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$REPO_ROOT/.build/release/QRCodeGenerator" "$MACOS_DIR/"
strip "$MACOS_DIR/QRCodeGenerator"
cp "$REPO_ROOT/config/macos/Info.plist" "$CONTENTS_DIR/Info.plist"

if [ -d "$REPO_ROOT/Sources/Resources/Assets.xcassets" ]; then
    xcrun actool --compile "$RESOURCES_DIR" \
        --platform macosx \
        --minimum-deployment-target 11.0 \
        --app-icon AppIcon \
        --output-partial-info-plist "$CONTENTS_DIR/AssetCatalog-Info.plist" \
        "$REPO_ROOT/Sources/Resources/Assets.xcassets"
fi

cp "$REPO_ROOT/assets/icons/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
cp "$REPO_ROOT/config/macos/QRCodeGenerator.entitlements" "$CONTENTS_DIR/"
printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"
chmod +x "$MACOS_DIR/QRCodeGenerator"

echo "Release app bundle created: $APP_BUNDLE"

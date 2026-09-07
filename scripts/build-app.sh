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

echo "Building QR Code Generator..."
swift build -c release

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$REPO_ROOT/.build/release/QRCodeGenerator" "$MACOS_DIR/"
cp "$REPO_ROOT/config/macos/Info.plist" "$CONTENTS_DIR/Info.plist"
cp -R "$REPO_ROOT/Sources/Resources/Assets.xcassets" "$RESOURCES_DIR/"

if [ -f "$REPO_ROOT/assets/icons/AppIcon.icns" ]; then
    cp "$REPO_ROOT/assets/icons/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

chmod +x "$MACOS_DIR/QRCodeGenerator"
echo "App bundle created: $APP_BUNDLE"

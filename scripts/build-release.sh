#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$REPO_ROOT/dist"
BUILD_DIR="$OUTPUT_DIR/build"
APP_NAME="QR Code Generator"
APP_BUNDLE="$OUTPUT_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
BUNDLE_ID="${BUNDLE_ID:-com.example.qrcodegenerator}"
RELEASE_VERSION="${RELEASE_VERSION:-1.0.0}"
BUILD_VERSION="${BUILD_VERSION:-1}"

[[ "$BUNDLE_ID" =~ ^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$ ]] || { echo "BUNDLE_ID must be a reverse-DNS identifier." >&2; exit 1; }
[[ "$RELEASE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "RELEASE_VERSION must be Major.Minor.Patch." >&2; exit 1; }
[[ "$BUILD_VERSION" =~ ^[0-9]+(\.[0-9]+){0,2}$ ]] || { echo "BUILD_VERSION must contain one to three numeric components." >&2; exit 1; }

cd "$REPO_ROOT"
rm -rf "$BUILD_DIR" "$APP_BUNDLE"
mkdir -p "$OUTPUT_DIR" "$BUILD_DIR" "$MACOS_DIR" "$RESOURCES_DIR"

build_architecture() {
    local architecture="$1"
    local scratch_path="$BUILD_DIR/$architecture"
    echo "Building optimized $architecture release executable..."
    swift build -c release --triple "${architecture}-apple-macosx11.0" --scratch-path "$scratch_path" \
        -Xswiftc -O -Xswiftc -whole-module-optimization \
        -Xswiftc -cross-module-optimization -Xswiftc -enforce-exclusivity=checked
}

build_architecture arm64
build_architecture x86_64

lipo -create "$BUILD_DIR/arm64/release/QRCodeGenerator" \
    "$BUILD_DIR/x86_64/release/QRCodeGenerator" -output "$MACOS_DIR/QRCodeGenerator"
strip -x "$MACOS_DIR/QRCodeGenerator"
cp "$REPO_ROOT/config/macos/Info.plist" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $RELEASE_VERSION" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_VERSION" "$CONTENTS_DIR/Info.plist"

if [ -d "$REPO_ROOT/Sources/Resources/Assets.xcassets" ]; then
    xcrun actool --compile "$RESOURCES_DIR" \
        --platform macosx \
        --minimum-deployment-target 11.0 \
        --app-icon AppIcon \
        --output-partial-info-plist "$BUILD_DIR/AssetCatalog-Info.plist" \
        "$REPO_ROOT/Sources/Resources/Assets.xcassets"
fi

cp "$REPO_ROOT/assets/icons/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"
chmod +x "$MACOS_DIR/QRCodeGenerator"
lipo -archs "$MACOS_DIR/QRCodeGenerator"
plutil -lint "$CONTENTS_DIR/Info.plist"
echo "Release app bundle created: $APP_BUNDLE"

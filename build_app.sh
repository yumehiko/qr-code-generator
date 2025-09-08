#!/bin/bash

# Build script for QR Code Generator.app

set -e

echo "Building QR Code Generator.app..."

# Clean previous builds
rm -rf .build
rm -rf "QR Code Generator.app"

# Build the executable in release mode
echo "Building executable..."
swift build -c release

# Create app bundle structure
echo "Creating app bundle..."
APP_NAME="QR Code Generator"
APP_BUNDLE="$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# Copy executable
echo "Copying executable..."
cp ".build/release/QRCodeGenerator" "$MACOS/QRCodeGenerator"

# Copy Info.plist
echo "Copying Info.plist..."
cp "Info.plist" "$CONTENTS/Info.plist"

# Copy icon assets
echo "Copying icon assets..."
cp -r "Sources/Resources/Assets.xcassets" "$RESOURCES/"

# Create iconset directory for iconutil
echo "Preparing iconset..."
ICONSET_DIR="AppIcon.iconset"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

# Copy icon files with correct naming for iconutil
cp "Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_16x16.png" "$ICONSET_DIR/icon_16x16.png"
cp "Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_16x16@2x.png" "$ICONSET_DIR/icon_16x16@2x.png"
cp "Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_32x32.png" "$ICONSET_DIR/icon_32x32.png"
cp "Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_32x32@2x.png" "$ICONSET_DIR/icon_32x32@2x.png"
cp "Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" "$ICONSET_DIR/icon_128x128.png"
cp "Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" "$ICONSET_DIR/icon_128x128@2x.png"
cp "Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" "$ICONSET_DIR/icon_256x256.png"
cp "Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_256x256@2x.png" "$ICONSET_DIR/icon_256x256@2x.png"
cp "Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" "$ICONSET_DIR/icon_512x512.png"
cp "Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png" "$ICONSET_DIR/icon_512x512@2x.png"

# Create icon file from iconset
echo "Generating icns file..."
iconutil -c icns -o "$RESOURCES/AppIcon.icns" "$ICONSET_DIR"

# Clean up temporary iconset
rm -rf "$ICONSET_DIR"

# Set executable permissions
chmod +x "$MACOS/QRCodeGenerator"

echo "Build complete!"
echo "App bundle created: $APP_BUNDLE"
echo ""
echo "To run the app: open \"$APP_BUNDLE\""
echo "To distribute: compress \"$APP_BUNDLE\" to a .zip or .dmg file"
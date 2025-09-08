#!/bin/bash

echo "Building QR Code Generator..."

# Clean previous builds
rm -rf .build

# Build the application
swift build -c release

# Create app bundle structure
APP_NAME="QR Code Generator"
APP_BUNDLE="$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp .build/release/QRCodeGenerator "$MACOS_DIR/"

# Copy Info.plist
cp Info.plist "$CONTENTS_DIR/"

# Copy Assets
if [ -d "Sources/Resources/Assets.xcassets" ]; then
    cp -r Sources/Resources/Assets.xcassets "$RESOURCES_DIR/"
fi

echo "Build complete! You can find the app at: $APP_BUNDLE"
echo "To run the app, use: open '$APP_BUNDLE'"
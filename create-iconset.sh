#!/bin/bash

# Create a proper iconset from the existing PNG files
set -e

echo "Creating temporary iconset for icon generation..."

# Create temporary iconset directory
TEMP_ICONSET="temp.iconset"
rm -rf "$TEMP_ICONSET"
mkdir -p "$TEMP_ICONSET"

# Copy and rename files to match iconutil requirements
SOURCE_DIR="Sources/Resources/Assets.xcassets/AppIcon.appiconset"

# Copy files with correct naming for iconutil
cp "$SOURCE_DIR/icon_16x16.png" "$TEMP_ICONSET/icon_16x16.png"
cp "$SOURCE_DIR/icon_16x16@2x.png" "$TEMP_ICONSET/icon_16x16@2x.png"
cp "$SOURCE_DIR/icon_32x32.png" "$TEMP_ICONSET/icon_32x32.png"
cp "$SOURCE_DIR/icon_32x32@2x.png" "$TEMP_ICONSET/icon_32x32@2x.png"
cp "$SOURCE_DIR/icon_128x128.png" "$TEMP_ICONSET/icon_128x128.png"
cp "$SOURCE_DIR/icon_128x128@2x.png" "$TEMP_ICONSET/icon_128x128@2x.png"
cp "$SOURCE_DIR/icon_256x256.png" "$TEMP_ICONSET/icon_256x256.png"
cp "$SOURCE_DIR/icon_256x256@2x.png" "$TEMP_ICONSET/icon_256x256@2x.png"
cp "$SOURCE_DIR/icon_512x512.png" "$TEMP_ICONSET/icon_512x512.png"
cp "$SOURCE_DIR/icon_512x512@2x.png" "$TEMP_ICONSET/icon_512x512@2x.png"

# Create icns file
echo "Creating AppIcon.icns..."
iconutil -c icns -o "AppIcon.icns" "$TEMP_ICONSET"

# Clean up
rm -rf "$TEMP_ICONSET"

echo "✅ AppIcon.icns created successfully!"
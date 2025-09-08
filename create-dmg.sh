#!/bin/bash

# DMG creation script for QR Code Generator
set -e

echo "==============================================="
echo "QR Code Generator - DMG Creation"
echo "==============================================="

# Configuration
APP_NAME="QR Code Generator"
APP_BUNDLE="$APP_NAME.app"
DMG_NAME="QRCodeGenerator"
DMG_VERSION="1.0.0"
DMG_FILENAME="${DMG_NAME}-${DMG_VERSION}.dmg"
DMG_TEMP="${DMG_NAME}-temp.dmg"
DMG_VOLUME_NAME="QR Code Generator"
DMG_SIZE="50m"

# Check if app exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ Error: $APP_BUNDLE not found!"
    echo "📝 Please run ./build-release.sh first to build the app"
    exit 1
fi

# Clean up any existing DMG files
echo "🧹 Cleaning up old DMG files..."
rm -f "$DMG_FILENAME" "$DMG_TEMP"
rm -rf dmg-contents

# Create temporary directory for DMG contents
echo "📁 Creating DMG contents directory..."
mkdir -p dmg-contents

# Copy app bundle to DMG contents
echo "📋 Copying app bundle..."
cp -R "$APP_BUNDLE" dmg-contents/

# Create a symbolic link to Applications folder
echo "🔗 Creating Applications folder link..."
ln -s /Applications dmg-contents/Applications

# Create temporary DMG
echo "💿 Creating temporary DMG..."
hdiutil create -volname "$DMG_VOLUME_NAME" \
    -srcfolder dmg-contents \
    -ov -format UDRW \
    -size "$DMG_SIZE" \
    "$DMG_TEMP"

# Mount temporary DMG
echo "📂 Mounting temporary DMG..."
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_TEMP" | \
    egrep '^/dev/' | sed 1q | awk '{print $1}')

# Wait for mount to complete
sleep 2

# Set custom icon positions and window properties
echo "🎨 Setting DMG window properties..."
osascript <<EOT
tell application "Finder"
    tell disk "$DMG_VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 900, 400}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 72
        set background color of viewOptions to {65535, 65535, 65535}
        set position of item "$APP_NAME.app" of container window to {125, 150}
        set position of item "Applications" of container window to {375, 150}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOT

# Unmount temporary DMG
echo "📂 Unmounting temporary DMG..."
hdiutil detach "$DEVICE"

# Convert to compressed DMG
echo "🗜️ Converting to compressed DMG..."
hdiutil convert "$DMG_TEMP" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_FILENAME"

# Clean up
echo "🧹 Cleaning up temporary files..."
rm -f "$DMG_TEMP"
rm -rf dmg-contents

# Display result
echo ""
echo "==============================================="
echo "✅ DMG Creation Complete!"
echo "==============================================="
echo "📦 DMG File: $DMG_FILENAME"
echo "📊 Size: $(du -h "$DMG_FILENAME" | cut -f1)"
echo ""
echo "🚀 To install: Double-click $DMG_FILENAME and drag"
echo "   '$APP_NAME' to the Applications folder"
echo ""

# Optional: Verify DMG
echo "🔍 Verifying DMG..."
hdiutil verify "$DMG_FILENAME"

echo ""
echo "✨ DMG file is ready for distribution!"
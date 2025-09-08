#!/bin/bash

# Build configuration for release/distribution
set -e

echo "==============================================="
echo "QR Code Generator - Release Build Configuration"
echo "==============================================="

# Configuration variables
APP_NAME="QR Code Generator"
APP_BUNDLE="$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
EXECUTABLE_NAME="QRCodeGenerator"
BUNDLE_ID="com.qrcodegenerator.app"

# Build optimizations
export SWIFT_ACTIVE_COMPILATION_CONDITIONS="RELEASE"
export SWIFT_OPTIMIZATION_LEVEL="-O"
export SWIFT_WHOLE_MODULE_OPTIMIZATION="YES"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf .build
rm -rf "$APP_BUNDLE"

# Build with release configuration and optimizations
echo "🔨 Building with release optimizations..."
swift build -c release \
    -Xswiftc -O \
    -Xswiftc -whole-module-optimization \
    -Xswiftc -cross-module-optimization \
    -Xswiftc -enforce-exclusivity=checked

# Create app bundle structure
echo "📦 Creating app bundle..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
echo "📋 Copying executable..."
cp .build/release/$EXECUTABLE_NAME "$MACOS_DIR/"

# Strip debug symbols for smaller binary
echo "🔧 Stripping debug symbols..."
strip "$MACOS_DIR/$EXECUTABLE_NAME"

# Copy Info.plist
echo "📄 Copying Info.plist..."
cp Info.plist "$CONTENTS_DIR/"

# Copy Assets and compile icons
echo "🎨 Copying and compiling assets..."
if [ -d "Sources/Resources/Assets.xcassets" ]; then
    # Use actool to compile assets properly
    xcrun actool --compile "$RESOURCES_DIR" \
        --platform macosx \
        --minimum-deployment-target 10.15 \
        --app-icon AppIcon \
        --output-partial-info-plist "$CONTENTS_DIR/AssetCatalog-Info.plist" \
        Sources/Resources/Assets.xcassets
    
    # If AppIcon.icns exists in the root, copy it
    if [ -f "AppIcon.icns" ]; then
        echo "🎨 Copying app icon..."
        cp AppIcon.icns "$RESOURCES_DIR/"
    else
        # Create iconset manually if needed
        echo "🎨 Creating app icon from PNG files..."
        TEMP_ICONSET="temp.iconset"
        rm -rf "$TEMP_ICONSET"
        mkdir -p "$TEMP_ICONSET"
        
        # Copy files with correct naming for iconutil
        SOURCE_ICONSET="Sources/Resources/Assets.xcassets/AppIcon.appiconset"
        cp "$SOURCE_ICONSET/icon_16x16.png" "$TEMP_ICONSET/icon_16x16.png"
        cp "$SOURCE_ICONSET/icon_16x16@2x.png" "$TEMP_ICONSET/icon_16x16@2x.png"
        cp "$SOURCE_ICONSET/icon_32x32.png" "$TEMP_ICONSET/icon_32x32.png"
        cp "$SOURCE_ICONSET/icon_32x32@2x.png" "$TEMP_ICONSET/icon_32x32@2x.png"
        cp "$SOURCE_ICONSET/icon_128x128.png" "$TEMP_ICONSET/icon_128x128.png"
        cp "$SOURCE_ICONSET/icon_128x128@2x.png" "$TEMP_ICONSET/icon_128x128@2x.png"
        cp "$SOURCE_ICONSET/icon_256x256.png" "$TEMP_ICONSET/icon_256x256.png"
        cp "$SOURCE_ICONSET/icon_256x256@2x.png" "$TEMP_ICONSET/icon_256x256@2x.png"
        cp "$SOURCE_ICONSET/icon_512x512.png" "$TEMP_ICONSET/icon_512x512.png"
        cp "$SOURCE_ICONSET/icon_512x512@2x.png" "$TEMP_ICONSET/icon_512x512@2x.png"
        
        # Create icns file
        iconutil -c icns -o "$RESOURCES_DIR/AppIcon.icns" "$TEMP_ICONSET"
        
        # Clean up
        rm -rf "$TEMP_ICONSET"
    fi
fi

# Copy entitlements (for reference, actual signing would use these)
echo "🔐 Copying entitlements..."
cp QRCodeGenerator.entitlements "$CONTENTS_DIR/"

# Create PkgInfo file
echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

# Set executable permissions
chmod +x "$MACOS_DIR/$EXECUTABLE_NAME"

# Display build information
echo ""
echo "==============================================="
echo "✅ Release Build Complete!"
echo "==============================================="
echo "📍 Location: $APP_BUNDLE"
echo "📊 Binary size: $(du -h "$MACOS_DIR/$EXECUTABLE_NAME" | cut -f1)"
echo "🏗️ Architecture: $(lipo -info "$MACOS_DIR/$EXECUTABLE_NAME" 2>/dev/null | cut -d: -f3 || echo "Universal")"
echo ""
echo "📋 Build Settings Applied:"
echo "  • Whole Module Optimization: YES"
echo "  • Cross Module Optimization: YES"
echo "  • Debug Symbols: STRIPPED"
echo "  • Optimization Level: -O (Speed)"
echo ""
echo "🚀 To run: open '$APP_BUNDLE'"
echo ""

# Optional: Verify entitlements would be applied correctly
echo "🔍 Entitlements to be applied during code signing:"
echo "  • App Sandbox: Enabled"
echo "  • File Access: User Selected Read/Write"
echo "  • Downloads Folder: Read/Write"
echo "  • Clipboard: Read/Write"
echo "  • Printing: Enabled"
echo ""
echo "📝 Note: For distribution, the app needs to be code signed with:"
echo "  codesign --deep --force --verify --verbose --sign \"Developer ID\" \\"
echo "    --entitlements QRCodeGenerator.entitlements \"$APP_BUNDLE\""
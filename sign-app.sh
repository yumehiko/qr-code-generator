#!/bin/bash

# Ad-hoc signing script for QR Code Generator
set -e

echo "==============================================="
echo "QR Code Generator - Ad-hoc Signing"
echo "==============================================="

APP_NAME="QR Code Generator"
APP_BUNDLE="$APP_NAME.app"

# Check if app exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ Error: $APP_BUNDLE not found!"
    echo "📝 Please run ./build-release.sh first to build the app"
    exit 1
fi

# Remove any existing signatures
echo "🧹 Removing existing signatures..."
codesign --remove-signature "$APP_BUNDLE" 2>/dev/null || true

# Sign with ad-hoc signature (using "-" means ad-hoc)
echo "✍️ Signing app with ad-hoc signature..."
codesign --force --deep --sign - \
    --entitlements QRCodeGenerator.entitlements \
    --options runtime \
    "$APP_BUNDLE"

# Verify the signature
echo "🔍 Verifying signature..."
codesign --verify --verbose "$APP_BUNDLE"

# Display signature info
echo ""
echo "📋 Signature Information:"
codesign --display --verbose=2 "$APP_BUNDLE"

echo ""
echo "==============================================="
echo "✅ Ad-hoc Signing Complete!"
echo "==============================================="
echo ""
echo "📝 Notes:"
echo "  • The app is now signed with an ad-hoc signature"
echo "  • This reduces Gatekeeper warnings on the same machine"
echo "  • Other users will still see 'unidentified developer' warning"
echo "  • For full distribution without warnings, Apple Developer ID is needed"
echo ""
echo "🚀 Next step: Run ./create-dmg.sh to create a DMG with the signed app"
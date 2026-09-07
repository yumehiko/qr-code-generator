#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="$REPO_ROOT/Sources/Resources/Assets.xcassets/AppIcon.appiconset"
OUTPUT_FILE="$REPO_ROOT/assets/icons/AppIcon.icns"
TEMP_DIRECTORY="$(mktemp -d "${TMPDIR:-/tmp}/qr-code-generator.XXXXXX")"
TEMP_ICONSET="$TEMP_DIRECTORY/AppIcon.iconset"

cleanup() { rm -rf "$TEMP_DIRECTORY"; }
trap cleanup EXIT

mkdir -p "$TEMP_ICONSET"
for filename in icon_16x16.png icon_16x16@2x.png icon_32x32.png icon_32x32@2x.png icon_128x128.png icon_128x128@2x.png icon_256x256.png icon_256x256@2x.png icon_512x512.png icon_512x512@2x.png; do
    cp "$SOURCE_DIR/$filename" "$TEMP_ICONSET/$filename"
done

iconutil -c icns -o "$OUTPUT_FILE" "$TEMP_ICONSET"
echo "Icon created: $OUTPUT_FILE"

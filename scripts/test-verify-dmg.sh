#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/qr-code-generator-verify-test.XXXXXX")"
cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

mkdir -p "$TEMP_DIR/bin" "$TEMP_DIR/temporary directory"
for command in hdiutil xcrun spctl codesign; do
  ln -s "$SCRIPT_DIR/test-support/mock-verify-dmg-command.sh" "$TEMP_DIR/bin/$command"
done
touch "$TEMP_DIR/release.dmg" "$TEMP_DIR/log"

TMPDIR="$TEMP_DIR/temporary directory" \
MOCK_LOG="$TEMP_DIR/log" \
PATH="$TEMP_DIR/bin:$PATH" \
"$SCRIPT_DIR/verify-dmg.sh" "$TEMP_DIR/release.dmg"

mount_point="$(awk -F: '/^mount:/ { print substr($0, 7); exit }' "$TEMP_DIR/log")"
[ -n "$mount_point" ]
[[ "$mount_point" == *"temporary directory"* ]]
grep -Fqx 'detach:/dev/disk77' "$TEMP_DIR/log"
[ ! -e "$mount_point" ]

echo "DMG verification mount and cleanup test passed."

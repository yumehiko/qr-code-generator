#!/bin/bash
set -euo pipefail
[ "$#" -eq 4 ] || { echo "Usage: $0 <app|dmg> <path> <api-key-path> <key-id>" >&2; exit 1; }
KIND="$1"; TARGET="$2"; API_KEY_PATH="$3"; KEY_ID="$4"
ISSUER_ID="${APPSTORE_CONNECT_ISSUER_ID:?APPSTORE_CONNECT_ISSUER_ID is required}"
[ -f "$API_KEY_PATH" ] || { echo "Notarization API key file not found." >&2; exit 1; }
case "$KIND" in
app)
  [ -d "$TARGET" ] || { echo "App bundle not found." >&2; exit 1; }
  ARCHIVE="$(mktemp "${TMPDIR:-/tmp}/qr-code-generator-notarize.XXXXXX.zip")"; trap 'rm -f "$ARCHIVE"' EXIT
  ditto -c -k --keepParent "$TARGET" "$ARCHIVE"
  xcrun notarytool submit "$ARCHIVE" --key "$API_KEY_PATH" --key-id "$KEY_ID" --issuer "$ISSUER_ID" --wait
  xcrun stapler staple "$TARGET"; xcrun stapler validate "$TARGET" ;;
dmg)
  [ -f "$TARGET" ] || { echo "DMG not found." >&2; exit 1; }
  xcrun notarytool submit "$TARGET" --key "$API_KEY_PATH" --key-id "$KEY_ID" --issuer "$ISSUER_ID" --wait
  xcrun stapler staple "$TARGET"; xcrun stapler validate "$TARGET" ;;
*) echo "Kind must be app or dmg." >&2; exit 1 ;;
esac

#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/qr-code-generator-release-test.XXXXXX")"
cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

ruby -ryaml -e '
  workflow = YAML.load_file(ARGV.fetch(0))
  runs = workflow.fetch("jobs").values.flat_map { |job| job.fetch("steps", []) }.map { |step| step["run"] }.compact
  abort "workflow run block contains expression expansion" if runs.any? { |run| run.include?("${{") }
' "$REPO_ROOT/.github/workflows/release.yml"

mkdir -p "$TEMP_DIR/bin"
cat > "$TEMP_DIR/bin/xcrun" <<'EOF'
#!/bin/bash
set -euo pipefail
if [ "$1" = notarytool ]; then
    shift
    while [ "$#" -gt 0 ]; do
        if [ "$1" = --key-id ]; then
            [ "$2" = "$EXPECTED_KEY_ID" ]
            exit 0
        fi
        shift
    done
    exit 1
fi
exit 0
EOF
chmod +x "$TEMP_DIR/bin/xcrun"
touch "$TEMP_DIR/release.dmg" "$TEMP_DIR/notary-key.p8"

MOCK_KEY_ID=$'quote" dollar$ backtick`\nline'
EXPECTED_KEY_ID="$MOCK_KEY_ID" \
APPSTORE_CONNECT_ISSUER_ID="issuer" \
PATH="$TEMP_DIR/bin:$PATH" \
"$SCRIPT_DIR/notarize.sh" dmg "$TEMP_DIR/release.dmg" "$TEMP_DIR/notary-key.p8" "$MOCK_KEY_ID"

echo "Release workflow expression and special-character key ID tests passed."

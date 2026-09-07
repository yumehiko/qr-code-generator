#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

"$SCRIPT_DIR/test.sh"
(cd "$REPO_ROOT" && swift build -c release)
echo "Unit tests and a release build completed successfully."
echo "For a bundle check, run scripts/build-app.sh."

#!/bin/bash

set -euo pipefail

./run_tests.sh
swift build -c release

echo "Unit tests and a release build completed successfully."
echo "For a manual bundle check, run: ./build.sh && open 'QR Code Generator.app'"

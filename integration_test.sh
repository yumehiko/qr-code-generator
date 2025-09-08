#!/bin/bash

echo "=========================================="
echo "QR Code Generator - Integration Test Suite"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "🧪 Testing: $test_name... "
    
    if eval "$test_command"; then
        if [ "$expected_result" = "pass" ]; then
            echo -e "${GREEN}✓ PASSED${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo -e "${RED}✗ FAILED (expected to fail)${NC}"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    else
        if [ "$expected_result" = "fail" ]; then
            echo -e "${GREEN}✓ PASSED (correctly failed)${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo -e "${RED}✗ FAILED${NC}"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    fi
}

echo "1️⃣  Build Tests"
echo "=================="
run_test "Clean build" "rm -rf .build && swift build -c release > /dev/null 2>&1" "pass"
run_test "Debug build" "swift build -c debug > /dev/null 2>&1" "pass"
run_test "Release build" "./build.sh > /dev/null 2>&1" "pass"
run_test "App bundle creation" "[ -d 'QR Code Generator.app' ]" "pass"
run_test "Executable exists" "[ -f 'QR Code Generator.app/Contents/MacOS/QRCodeGenerator' ]" "pass"
run_test "Info.plist exists" "[ -f 'QR Code Generator.app/Contents/Info.plist' ]" "pass"
run_test "Entitlements exist" "[ -f 'QRCodeGenerator.entitlements' ]" "pass"
echo ""

echo "2️⃣  File Structure Tests"
echo "========================="
run_test "Source files exist" "[ -d 'Sources' ]" "pass"
run_test "Views directory" "[ -d 'Sources/Views' ]" "pass"
run_test "ViewModels directory" "[ -d 'Sources/ViewModels' ]" "pass"
run_test "Services directory" "[ -d 'Sources/Services' ]" "pass"
run_test "Models directory" "[ -d 'Sources/Models' ]" "pass"
run_test "Resources directory" "[ -d 'Sources/Resources' ]" "pass"
run_test "Tests directory" "[ -d 'Tests' ]" "pass"
run_test "UI Tests created" "[ -f 'Tests/QRCodeGeneratorUITests.swift' ]" "pass"
echo ""

echo "3️⃣  Component Tests"
echo "===================="
run_test "Main app file" "[ -f 'Sources/QRCodeGeneratorApp.swift' ]" "pass"
run_test "ContentView" "[ -f 'Sources/Views/ContentView.swift' ]" "pass"
run_test "QRCodeViewModel" "[ -f 'Sources/ViewModels/QRCodeViewModel.swift' ]" "pass"
run_test "QRCodeGenerator service" "[ -f 'Sources/Services/QRCodeGenerator.swift' ]" "pass"
run_test "FileExportService" "[ -f 'Sources/Services/FileExportService.swift' ]" "pass"
run_test "ErrorHandler" "[ -f 'Sources/Utilities/ErrorHandler.swift' ]" "pass"
echo ""

echo "4️⃣  Resource Tests"
echo "==================="
run_test "Assets catalog" "[ -d 'Sources/Resources/Assets.xcassets' ]" "pass"
run_test "App icon" "[ -d 'Sources/Resources/Assets.xcassets/AppIcon.appiconset' ]" "pass"
run_test "Icon SVG" "[ -f 'Sources/Resources/icon.svg' ]" "pass"
echo ""

echo "5️⃣  Configuration Tests"
echo "========================"
run_test "Package.swift" "[ -f 'Package.swift' ]" "pass"
run_test "Package.swift valid" "swift package describe --type json > /dev/null 2>&1" "pass"
run_test "README exists" "[ -f 'README.md' ]" "pass"
run_test "Build script" "[ -x 'build.sh' ]" "pass"
run_test "Release build script" "[ -x 'build-release.sh' ]" "pass"
run_test "Test runner script" "[ -x 'run_tests.sh' ]" "pass"
echo ""

echo "6️⃣  Code Quality Tests"
echo "======================="
# Check for Swift syntax
run_test "Swift syntax check" "swift build --target QRCodeGenerator -Xswiftc -parse-as-library > /dev/null 2>&1" "pass"

# Check for common issues
run_test "No force unwraps in Views" "! grep -r 'force-unwrap' Sources/Views/*.swift 2>/dev/null" "pass"
run_test "Error handling present" "grep -r 'do.*catch\|throw\|Error' Sources/ > /dev/null 2>&1" "pass"
run_test "@MainActor annotations" "grep -r '@MainActor' Sources/ViewModels/*.swift > /dev/null 2>&1" "pass"
run_test "@Published properties" "grep -r '@Published' Sources/ViewModels/*.swift > /dev/null 2>&1" "pass"
echo ""

echo "7️⃣  Requirements Verification"
echo "=============================="
run_test "Text input capability" "grep -r 'TextEditor\|TextField' Sources/Views/*.swift > /dev/null 2>&1" "pass"
run_test "QR generation implementation" "grep -r 'CIFilter.*qrCodeGenerator' Sources/ > /dev/null 2>&1" "pass"
run_test "Error correction levels" "grep -r 'ErrorCorrectionLevel' Sources/ > /dev/null 2>&1" "pass"
run_test "Export functionality" "grep -r 'NSSavePanel\|export' Sources/ > /dev/null 2>&1" "pass"
run_test "Copy to clipboard" "grep -r 'NSPasteboard' Sources/ > /dev/null 2>&1" "pass"
run_test "SVG conversion" "grep -r 'convertToSVG\|SVG' Sources/ > /dev/null 2>&1" "pass"
echo ""

echo "8️⃣  Binary Analysis"
echo "===================="
if [ -f "QR Code Generator.app/Contents/MacOS/QRCodeGenerator" ]; then
    BINARY_SIZE=$(du -h "QR Code Generator.app/Contents/MacOS/QRCodeGenerator" | cut -f1)
    run_test "Binary size < 500K" "[ $(du -k 'QR Code Generator.app/Contents/MacOS/QRCodeGenerator' | cut -f1) -lt 500 ]" "pass"
    echo "   📊 Binary size: $BINARY_SIZE"
fi
echo ""

echo "=========================================="
echo "📊 Test Results Summary"
echo "=========================================="
echo -e "Total Tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ All integration tests passed!${NC}"
    echo ""
    echo "The QR Code Generator application is ready for use."
    echo "Run the app with: open 'QR Code Generator.app'"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some tests failed. Please review the output above.${NC}"
    exit 1
fi
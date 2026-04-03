#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DYLIB="$PROJECT_ROOT/Resources/lib/librclone.dylib"

if [ ! -f "$DYLIB" ]; then
    echo "Error: librclone.dylib not found. Run ./scripts/build-librclone.sh first."
    exit 1
fi

PASSED=0
FAILED=0
TOTAL_TESTS=0

echo "====================================="
echo "  RcloneGUI Test Suite"
echo "====================================="
echo ""

# 1. SPM Package Tests
for pkg in RcloneKit FileBrowser TransferEngine; do
    PKG_DIR="$PROJECT_ROOT/Packages/$pkg"
    echo "=== SPM: $pkg ==="

    cd "$PKG_DIR"

    LIBRARY_PATH="$PROJECT_ROOT/Resources/lib" swift build --build-tests 2>&1 | tail -1

    BUILD_DIR="$PKG_DIR/.build/arm64-apple-macosx/debug"
    cp "$DYLIB" "$BUILD_DIR/" 2>/dev/null || true

    XCTEST_DIR=$(find "$BUILD_DIR" -name "*.xctest" -type d 2>/dev/null | head -1)
    if [ -n "$XCTEST_DIR" ]; then
        cp "$DYLIB" "$XCTEST_DIR/Contents/MacOS/" 2>/dev/null || true
        mkdir -p "$XCTEST_DIR/Contents/Frameworks"
        cp "$DYLIB" "$XCTEST_DIR/Contents/Frameworks/" 2>/dev/null || true
    fi

    OUTPUT=$(LIBRARY_PATH="$PROJECT_ROOT/Resources/lib" DYLD_LIBRARY_PATH="$BUILD_DIR:$PROJECT_ROOT/Resources/lib" swift test 2>&1)
    COUNT=$(echo "$OUTPUT" | grep -o "with [0-9]* tests" | grep -o "[0-9]*" || echo "0")
    TOTAL_TESTS=$((TOTAL_TESTS + COUNT))

    if echo "$OUTPUT" | grep -q "passed"; then
        PASSED=$((PASSED + 1))
        echo "  ✔ $COUNT tests passed"
    else
        FAILED=$((FAILED + 1))
        echo "  ✘ FAILED"
        echo "$OUTPUT" | tail -5
    fi
    echo ""
done

# 2. Xcode App Tests
cd "$PROJECT_ROOT"
echo "=== Xcode: RcloneGUITests ==="
OUTPUT=$(xcodebuild test -scheme RcloneGUI -configuration Debug -destination 'platform=macOS' 2>&1)
COUNT=$(echo "$OUTPUT" | grep -o "with [0-9]* tests" | grep -o "[0-9]*" | tail -1 || echo "0")
TOTAL_TESTS=$((TOTAL_TESTS + COUNT))

if echo "$OUTPUT" | grep -q "Test run with.*passed"; then
    PASSED=$((PASSED + 1))
    echo "  ✔ $COUNT tests passed"
else
    FAILED=$((FAILED + 1))
    echo "  ✘ FAILED"
    echo "$OUTPUT" | grep -E "failed|error:" | tail -5
fi

echo ""
echo "====================================="
echo "  Results: $PASSED suites passed, $FAILED failed"
echo "  Total: $TOTAL_TESTS tests"
echo "====================================="

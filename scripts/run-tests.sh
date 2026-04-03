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

for pkg in RcloneKit FileBrowser TransferEngine; do
    PKG_DIR="$PROJECT_ROOT/Packages/$pkg"
    echo "=== Testing $pkg ==="

    cd "$PKG_DIR"

    # Build first
    LIBRARY_PATH="$PROJECT_ROOT/Resources/lib" swift build --build-tests 2>&1 | tail -3

    # Copy dylib to all places the test runner might look
    BUILD_DIR="$PKG_DIR/.build/arm64-apple-macosx/debug"
    cp "$DYLIB" "$BUILD_DIR/" 2>/dev/null || true

    # Also copy into xctest bundle
    XCTEST_DIR=$(find "$BUILD_DIR" -name "*.xctest" -type d 2>/dev/null | head -1)
    if [ -n "$XCTEST_DIR" ]; then
        cp "$DYLIB" "$XCTEST_DIR/Contents/MacOS/" 2>/dev/null || true
        # Also put in Frameworks
        mkdir -p "$XCTEST_DIR/Contents/Frameworks"
        cp "$DYLIB" "$XCTEST_DIR/Contents/Frameworks/" 2>/dev/null || true
    fi

    # Run tests
    if LIBRARY_PATH="$PROJECT_ROOT/Resources/lib" DYLD_LIBRARY_PATH="$BUILD_DIR:$PROJECT_ROOT/Resources/lib" swift test 2>&1 | tee /tmp/test-$pkg.log | tail -5; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi

    echo ""
done

echo "=== Results: $PASSED passed, $FAILED failed ==="

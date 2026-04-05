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
FAILED_SUITES=()
START_TIME=$(date +%s)

echo "====================================="
echo "  RcloneGUI Test Suite"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
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
        FAILED_SUITES+=("SPM:$pkg")
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
SUITES=$(echo "$OUTPUT" | grep -o "in [0-9]* suites" | grep -o "[0-9]*" | tail -1 || echo "0")
TOTAL_TESTS=$((TOTAL_TESTS + COUNT))

if echo "$OUTPUT" | grep -q "Test run with.*passed"; then
    PASSED=$((PASSED + 1))
    echo "  ✔ $COUNT tests in $SUITES suites passed"
else
    FAILED=$((FAILED + 1))
    FAILED_SUITES+=("Xcode:RcloneGUITests")
    echo "  ✘ FAILED"
    echo "$OUTPUT" | grep -E "✘|failed|error:" | head -10
fi

# Show per-suite breakdown
echo ""
echo "  Test suites:"
echo "$OUTPUT" | grep -E "^[✔✘] Suite" | while read -r line; do
    echo "    $line"
done

# 3. Build Warnings Check
echo ""
echo "=== Build Warnings ==="
WARNINGS=$(xcodebuild -scheme RcloneGUI -configuration Debug build 2>&1 | grep "warning:" | grep -v "export\|Run script\|DYLIB_INSTALL" | sort -u)
WARN_COUNT=$(echo "$WARNINGS" | grep -c "warning:" 2>/dev/null || echo "0")
if [ "$WARN_COUNT" -gt 0 ]; then
    echo "  ⚠ $WARN_COUNT warning(s):"
    echo "$WARNINGS" | head -10 | while read -r line; do
        echo "    $line"
    done
else
    echo "  ✔ 0 warnings"
fi

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo ""
echo "====================================="
echo "  Results"
echo "====================================="
echo "  Suites: $PASSED passed, $FAILED failed"
echo "  Tests:  $TOTAL_TESTS total"
echo "  Time:   ${ELAPSED}s"
if [ ${#FAILED_SUITES[@]} -gt 0 ]; then
    echo ""
    echo "  Failed:"
    for suite in "${FAILED_SUITES[@]}"; do
        echo "    ✘ $suite"
    done
fi
echo "====================================="

exit $FAILED

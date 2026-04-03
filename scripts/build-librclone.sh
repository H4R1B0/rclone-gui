#!/bin/bash
set -euo pipefail

RCLONE_VERSION="v1.68.2"
BUILD_DIR="$(pwd)/.build/rclone"
OUTPUT_DIR="$(pwd)/Resources/lib"

mkdir -p "$OUTPUT_DIR"

if [ ! -d "$BUILD_DIR" ]; then
    git clone --depth 1 --branch "$RCLONE_VERSION" https://github.com/rclone/rclone.git "$BUILD_DIR"
fi

cd "$BUILD_DIR"

CGO_ENABLED=1 \
    CGO_CFLAGS="-mmacosx-version-min=14.0" \
    CGO_LDFLAGS="-mmacosx-version-min=14.0" \
    go build -buildmode=c-shared \
    -o "$OUTPUT_DIR/librclone.dylib" \
    github.com/rclone/rclone/librclone

# Fix install name for @rpath loading
install_name_tool -id "@rpath/librclone.dylib" "$OUTPUT_DIR/librclone.dylib"

echo "Built librclone.dylib at $OUTPUT_DIR/librclone.dylib"

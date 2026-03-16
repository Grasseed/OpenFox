#!/bin/bash
# Build OpenFox.app for macOS
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/OpenFox.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"

echo "========================================="
echo "  OpenFox.app Builder"
echo "========================================="
echo ""

# Clean previous build
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$BUILD_DIR"

# Step 1: Build the Swift executable
echo "[1/4] Compiling Swift sources..."
cd "$SCRIPT_DIR"
swift build -c release 2>&1 | tail -5

BINARY_PATH=$(swift build -c release --show-bin-path)/OpenFox
if [ ! -f "$BINARY_PATH" ]; then
    echo "ERROR: Build failed, binary not found at $BINARY_PATH"
    exit 1
fi
echo "  Binary: $BINARY_PATH"

# Step 2: Create .app bundle
echo "[2/4] Creating app bundle..."
cp "$BINARY_PATH" "$MACOS_DIR/OpenFox"
cp "$SCRIPT_DIR/Info.plist" "$CONTENTS/Info.plist"

# Copy SPM resource bundle (contains bundled OpenFox JS project files)
BIN_DIR=$(swift build -c release --show-bin-path)
RESOURCE_BUNDLE=$(find "$BIN_DIR" -name "*.bundle" -type d | head -1)
if [ -n "$RESOURCE_BUNDLE" ]; then
    cp -R "$RESOURCE_BUNDLE" "$RESOURCES_DIR/"
    echo "  Resource bundle: $(basename $RESOURCE_BUNDLE)"
else
    echo "  Warning: No resource bundle found"
fi

# Step 3: Generate app icon
echo "[3/4] Generating app icon..."
APP_DIR="$SCRIPT_DIR" bash "$SCRIPT_DIR/scripts/generate-icon.sh" 2>/dev/null || true
if [ -f "$BUILD_DIR/AppIcon.icns" ]; then
    cp "$BUILD_DIR/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
    echo "  Icon copied to bundle"
else
    echo "  Warning: No icon generated, using default"
fi

# Step 4: Sign the app (ad-hoc for local use)
echo "[4/4] Signing app bundle..."
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || {
    echo "  Warning: Code signing failed (app will still work locally)"
}

echo ""
echo "========================================="
echo "  Build Complete!"
echo "========================================="
echo "  App: $APP_BUNDLE"
echo ""
echo "  To install: drag OpenFox.app to /Applications"
echo "  To create DMG: ./create-dmg.sh"
echo ""

# Print app size
APP_SIZE=$(du -sh "$APP_BUNDLE" | cut -f1)
echo "  Size: $APP_SIZE"

#!/bin/bash
# Create a DMG installer for OpenFox.app
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/OpenFox.app"
DMG_NAME="OpenFox-Installer"
DMG_PATH="$BUILD_DIR/$DMG_NAME.dmg"
STAGING_DIR="$BUILD_DIR/dmg-staging"
VERSION="1.0.0"

echo "========================================="
echo "  OpenFox DMG Creator"
echo "========================================="
echo ""

# Check that the app exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "OpenFox.app not found. Building first..."
    bash "$SCRIPT_DIR/build.sh"
fi

# Clean previous DMG
rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"

echo "[1/3] Preparing DMG contents..."
# Copy app to staging
cp -R "$APP_BUNDLE" "$STAGING_DIR/"

# Create Applications symlink for drag-to-install
ln -s /Applications "$STAGING_DIR/Applications"

# Create a background instructions file
cat > "$STAGING_DIR/.background_readme.txt" << 'EOF'
Drag OpenFox.app to Applications to install.
EOF

echo "[2/3] Creating DMG image..."
# Create DMG using hdiutil
hdiutil create \
    -volname "OpenFox $VERSION" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$DMG_PATH" 2>/dev/null

echo "[3/3] Cleaning up..."
rm -rf "$STAGING_DIR"

# Print result
DMG_SIZE=$(du -sh "$DMG_PATH" | cut -f1)

echo ""
echo "========================================="
echo "  DMG Created Successfully!"
echo "========================================="
echo "  File: $DMG_PATH"
echo "  Size: $DMG_SIZE"
echo ""
echo "  Users can open the DMG and drag"
echo "  OpenFox.app to their Applications folder."
echo ""

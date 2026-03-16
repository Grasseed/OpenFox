#!/bin/bash
# Create a styled DMG installer for OpenFox.app
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/OpenFox.app"
DMG_RW="$BUILD_DIR/OpenFox-rw.dmg"
DMG_FINAL="$BUILD_DIR/OpenFox-Installer.dmg"
STAGING_DIR="/tmp/openfox_dmg_staging"
VERSION="1.0.0"
VOL_NAME="OpenFox $VERSION"
BG_IMG="$BUILD_DIR/dmg_background.png"

echo "========================================="
echo "  OpenFox DMG Creator"
echo "========================================="
echo ""

# Build app if needed
if [ ! -d "$APP_BUNDLE" ]; then
    echo "OpenFox.app not found. Building first..."
    bash "$SCRIPT_DIR/build.sh"
fi

# Clean
rm -rf "$STAGING_DIR" "$DMG_RW" "$DMG_FINAL"
mkdir -p "$STAGING_DIR/.background"

echo "[1/4] Generating DMG background..."
python3 "$SCRIPT_DIR/scripts/generate-dmg-bg.py" "$BG_IMG" 2>/dev/null \
    && cp "$BG_IMG" "$STAGING_DIR/.background/background.png" \
    && echo "  Background generated" \
    || echo "  Skipping background (generation failed)"

echo "[2/4] Preparing DMG contents..."
cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -sf /Applications "$STAGING_DIR/Applications"

echo "[3/4] Creating compressed DMG..."
rm -f "$DMG_FINAL"
hdiutil create \
    -volname "$VOL_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov -format UDZO \
    -imagekey zlib-level=9 \
    "$DMG_FINAL" > /dev/null

rm -rf "$STAGING_DIR"

echo "[4/4] Applying Finder settings..."
# Mount final DMG to set icon positions (best-effort)
MOUNT_PT=$(hdiutil attach "$DMG_FINAL" -noverify -noautoopen 2>/dev/null \
    | awk '/Apple_HFS/{print $NF}')
if [ -n "$MOUNT_PT" ]; then
    osascript <<APPLESCRIPT 2>/dev/null || true
tell application "Finder"
  tell disk "$VOL_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {200, 120, 860, 540}
    set theViewOptions to icon view options of container window
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to 100
    set text size of theViewOptions to 13
    try
      set background picture of theViewOptions to file ".background:background.png"
    end try
    set position of item "OpenFox.app"   of container window to {165, 190}
    set position of item "Applications"  of container window to {495, 190}
    close
    update without registering applications
    delay 1
  end tell
end tell
APPLESCRIPT
    hdiutil detach "$MOUNT_PT" -force 2>/dev/null || true
fi

DMG_SIZE=$(du -sh "$DMG_FINAL" | cut -f1)

echo ""
echo "========================================="
echo "  DMG Created Successfully!"
echo "========================================="
echo "  File: $DMG_FINAL"
echo "  Size: $DMG_SIZE"
echo ""
echo "  Open the DMG and drag OpenFox.app"
echo "  to the Applications folder to install."
echo ""

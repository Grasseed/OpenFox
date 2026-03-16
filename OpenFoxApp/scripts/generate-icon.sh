#!/bin/bash
# Generate app icon using macOS built-in tools
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
ICON_DIR="$APP_DIR/build/AppIcon.iconset"

mkdir -p "$ICON_DIR"

# Create a fox-themed icon using Core Graphics via Python
python3 << 'PYEOF'
import subprocess, os, tempfile

svg = '''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#FF8C00"/>
      <stop offset="100%" style="stop-color:#FF5500"/>
    </linearGradient>
    <linearGradient id="fox" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#FFFFFF"/>
      <stop offset="100%" style="stop-color:#FFF5E6"/>
    </linearGradient>
  </defs>
  <!-- Background -->
  <rect width="1024" height="1024" rx="220" fill="url(#bg)"/>
  <!-- Fox face - simplified geometric -->
  <!-- Left ear -->
  <polygon points="280,200 380,420 180,420" fill="url(#fox)" opacity="0.95"/>
  <polygon points="300,260 360,400 220,400" fill="#FF8C00" opacity="0.5"/>
  <!-- Right ear -->
  <polygon points="744,200 644,420 844,420" fill="url(#fox)" opacity="0.95"/>
  <polygon points="724,260 664,400 804,400" fill="#FF8C00" opacity="0.5"/>
  <!-- Head -->
  <ellipse cx="512" cy="540" rx="250" ry="230" fill="url(#fox)" opacity="0.95"/>
  <!-- Inner face / cheeks -->
  <ellipse cx="512" cy="600" rx="180" ry="160" fill="#FFF5E6"/>
  <!-- Eyes -->
  <ellipse cx="420" cy="500" rx="32" ry="36" fill="#2D2D2D"/>
  <ellipse cx="604" cy="500" rx="32" ry="36" fill="#2D2D2D"/>
  <!-- Eye highlights -->
  <ellipse cx="410" cy="490" rx="12" ry="14" fill="white" opacity="0.8"/>
  <ellipse cx="594" cy="490" rx="12" ry="14" fill="white" opacity="0.8"/>
  <!-- Nose -->
  <ellipse cx="512" cy="580" rx="24" ry="18" fill="#2D2D2D"/>
  <!-- Mouth -->
  <path d="M 488 600 Q 512 630 536 600" fill="none" stroke="#2D2D2D" stroke-width="6" stroke-linecap="round"/>
  <!-- Bolt symbol (bottom) -->
  <polygon points="490,700 520,740 506,740 530,790 500,750 514,750" fill="#FFD700" opacity="0.9"/>
</svg>'''

# Write SVG and convert
tmpdir = os.environ.get("TMPDIR", "/tmp")
svg_path = os.path.join(tmpdir, "openfox_icon.svg")
with open(svg_path, "w") as f:
    f.write(svg)

icon_dir = os.path.join(os.environ.get("APP_DIR", "."), "build", "AppIcon.iconset")

sizes = [16, 32, 64, 128, 256, 512, 1024]
for size in sizes:
    out = os.path.join(icon_dir, f"icon_{size}x{size}.png")
    # Use qlmanage for SVG to PNG conversion (available on macOS)
    # Fallback: use sips
    subprocess.run([
        "sips", "-s", "format", "png",
        "-z", str(size), str(size),
        svg_path, "--out", out
    ], capture_output=True)

    # Also create @2x versions
    if size <= 512:
        out2x = os.path.join(icon_dir, f"icon_{size}x{size}@2x.png")
        doubled = size * 2
        subprocess.run([
            "sips", "-s", "format", "png",
            "-z", str(doubled), str(doubled),
            svg_path, "--out", out2x
        ], capture_output=True)

os.remove(svg_path)
PYEOF

# Rename to standard iconset names
cd "$ICON_DIR"
[ -f icon_16x16.png ]    && mv icon_16x16.png icon_16x16.png 2>/dev/null || true
[ -f icon_32x32.png ]    && true || true
[ -f icon_128x128.png ]  && true || true
[ -f icon_256x256.png ]  && true || true
[ -f icon_512x512.png ]  && true || true

# Generate icns
iconutil -c icns "$ICON_DIR" -o "$APP_DIR/build/AppIcon.icns" 2>/dev/null || {
    echo "Warning: iconutil failed, icon will use default"
}

echo "Icon generated at $APP_DIR/build/AppIcon.icns"

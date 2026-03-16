#!/usr/bin/env python3
"""Generate a beautiful DMG background image using Quartz/CoreGraphics via ctypes."""
import subprocess, sys, os

out_path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/dmg_bg.png"

# Use Swift to render the background (most reliable on macOS)
swift_code = r"""
import AppKit
import CoreGraphics

let width: CGFloat = 660
let height: CGFloat = 400
let scale: CGFloat = 2  // @2x

let bitmapRep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(width * scale),
    pixelsHigh: Int(height * scale),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!
bitmapRep.size = NSSize(width: width, height: height)

NSGraphicsContext.saveGraphicsState()
let ctx = NSGraphicsContext(bitmapImageRep: bitmapRep)!
NSGraphicsContext.current = ctx
let cgCtx = ctx.cgContext

// Background - warm off-white like macOS DMG
let bgColor = CGColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0)
cgCtx.setFillColor(bgColor)
cgCtx.fill(CGRect(x: 0, y: 0, width: width, height: height))

// Subtle gradient overlay
let colors = [
    CGColor(red: 0.97, green: 0.97, blue: 0.95, alpha: 1.0),
    CGColor(red: 0.93, green: 0.93, blue: 0.91, alpha: 1.0)
] as CFArray
let locations: [CGFloat] = [0.0, 1.0]
let colorSpace = CGColorSpaceCreateDeviceRGB()
let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations)!
cgCtx.drawLinearGradient(gradient,
    start: CGPoint(x: width/2, y: height),
    end: CGPoint(x: width/2, y: 0),
    options: [])

// Left icon area - app icon placeholder circle (fox orange)
let iconX: CGFloat = 165
let iconY: CGFloat = height / 2
let iconR: CGFloat = 68

// Shadow for left icon
cgCtx.saveGState()
cgCtx.setShadow(offset: CGSize(width: 0, height: -4), blur: 20,
    color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.2))
let foxGradColors = [
    CGColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 1.0),
    CGColor(red: 1.0, green: 0.38, blue: 0.0, alpha: 1.0)
] as CFArray
let foxGrad = CGGradient(colorsSpace: colorSpace, colors: foxGradColors, locations: locations)!
cgCtx.addEllipse(in: CGRect(x: iconX - iconR, y: iconY - iconR, width: iconR*2, height: iconR*2))
cgCtx.clip()
cgCtx.drawLinearGradient(foxGrad,
    start: CGPoint(x: iconX - iconR, y: iconY + iconR),
    end: CGPoint(x: iconX + iconR, y: iconY - iconR),
    options: [])
cgCtx.restoreGState()

// Fox emoji text
let foxAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 56),
]
let foxStr = NSAttributedString(string: "🦊", attributes: foxAttrs)
let foxSize = foxStr.size()
foxStr.draw(at: NSPoint(x: iconX - foxSize.width/2, y: iconY - foxSize.height/2))

// App name under icon
let nameAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
    .foregroundColor: NSColor(calibratedWhite: 0.25, alpha: 1.0)
]
let nameStr = NSAttributedString(string: "OpenFox", attributes: nameAttrs)
let nameSize = nameStr.size()
nameStr.draw(at: NSPoint(x: iconX - nameSize.width/2, y: iconY - iconR - 28))

// Arrow in the middle
let arrowX: CGFloat = width / 2
let arrowY: CGFloat = height / 2

cgCtx.setFillColor(CGColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 0.7))
let arrowW: CGFloat = 44
let arrowH: CGFloat = 22
let shaftH: CGFloat = 10
let shaftY = arrowY - shaftH/2
// Shaft
cgCtx.fill(CGRect(x: arrowX - arrowW/2, y: shaftY, width: arrowW - 14, height: shaftH))
// Arrowhead
let points = [
    CGPoint(x: arrowX + arrowW/2, y: arrowY),
    CGPoint(x: arrowX + arrowW/2 - 16, y: arrowY + arrowH/2),
    CGPoint(x: arrowX + arrowW/2 - 16, y: arrowY - arrowH/2)
]
cgCtx.move(to: points[0])
cgCtx.addLine(to: points[1])
cgCtx.addLine(to: points[2])
cgCtx.closePath()
cgCtx.fillPath()

// Right area - Applications folder
let appX: CGFloat = width - 165
let appY: CGFloat = height / 2
let appR: CGFloat = 68

// Shadow for right folder
cgCtx.saveGState()
cgCtx.setShadow(offset: CGSize(width: 0, height: -4), blur: 20,
    color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.15))

// Dashed border circle for Applications
cgCtx.setStrokeColor(CGColor(red: 0.65, green: 0.65, blue: 0.65, alpha: 1.0))
cgCtx.setLineWidth(2.5)
cgCtx.setLineDash(phase: 0, lengths: [8, 4])
let appRect = CGRect(x: appX - appR, y: appY - appR, width: appR*2, height: appR*2)
let appPath = CGPath(roundedRect: appRect, cornerWidth: 20, cornerHeight: 20, transform: nil)
cgCtx.addPath(appPath)
cgCtx.strokePath()
cgCtx.restoreGState()

// Folder emoji
let folderAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 52),
]
let folderStr = NSAttributedString(string: "📂", attributes: folderAttrs)
let folderSize = folderStr.size()
folderStr.draw(at: NSPoint(x: appX - folderSize.width/2, y: appY - folderSize.height/2))

// Applications label
let appLabelAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
    .foregroundColor: NSColor(calibratedWhite: 0.25, alpha: 1.0)
]
let appLabelStr = NSAttributedString(string: "Applications", attributes: appLabelAttrs)
let appLabelSize = appLabelStr.size()
appLabelStr.draw(at: NSPoint(x: appX - appLabelSize.width/2, y: appY - appR - 28))

// Bottom instruction text
let instrAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 11),
    .foregroundColor: NSColor(calibratedWhite: 0.5, alpha: 1.0)
]
let instrStr = NSAttributedString(string: "Drag OpenFox to your Applications folder to install.", attributes: instrAttrs)
let instrSize = instrStr.size()
instrStr.draw(at: NSPoint(x: width/2 - instrSize.width/2, y: 28))

NSGraphicsContext.restoreGraphicsState()

// Save PNG
if let data = bitmapRep.representation(using: .png, properties: [:]) {
    let url = URL(fileURLWithPath: CommandLine.arguments[1])
    try! data.write(to: url)
    print("Background saved to \(url.path)")
}
"""

# Write Swift file and compile
tmp = "/tmp/gen_dmg_bg.swift"
with open(tmp, "w") as f:
    f.write(swift_code)

result = subprocess.run(
    ["swift", tmp, out_path],
    capture_output=True, text=True
)
if result.returncode != 0:
    print("Error:", result.stderr, file=sys.stderr)
    sys.exit(1)
print(result.stdout.strip())

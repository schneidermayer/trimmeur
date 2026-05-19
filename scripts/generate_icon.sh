#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESOURCE_DIR="${ROOT_DIR}/Sources/TrimmeurMacOS/Resources"
ICON_BUILD_DIR="${ROOT_DIR}/dist/.iconbuild"
ICONSET_DIR="${ICON_BUILD_DIR}/AppIcon.iconset"
ICNS_PATH="${RESOURCE_DIR}/AppIcon.icns"
TMP_SWIFT="$(mktemp -t trimmeur-icon.XXXXXX.swift)"

cleanup() {
  rm -f "${TMP_SWIFT}"
}
trap cleanup EXIT

rm -rf "${ICONSET_DIR}"
mkdir -p "${RESOURCE_DIR}" "${ICONSET_DIR}"

cat > "${TMP_SWIFT}" <<'SWIFT'
import AppKit

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)

struct IconSlot {
    let filename: String
    let points: CGFloat
    let scale: CGFloat

    var pixels: Int { Int(points * scale) }
}

let slots = [
    IconSlot(filename: "icon_16x16.png", points: 16, scale: 1),
    IconSlot(filename: "icon_16x16@2x.png", points: 16, scale: 2),
    IconSlot(filename: "icon_32x32.png", points: 32, scale: 1),
    IconSlot(filename: "icon_32x32@2x.png", points: 32, scale: 2),
    IconSlot(filename: "icon_128x128.png", points: 128, scale: 1),
    IconSlot(filename: "icon_128x128@2x.png", points: 128, scale: 2),
    IconSlot(filename: "icon_256x256.png", points: 256, scale: 1),
    IconSlot(filename: "icon_256x256@2x.png", points: 256, scale: 2),
    IconSlot(filename: "icon_512x512.png", points: 512, scale: 1),
    IconSlot(filename: "icon_512x512@2x.png", points: 512, scale: 2),
]

func drawIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor(red: 0.94, green: 0.97, blue: 1.0, alpha: 1).setFill()
    NSBezierPath(roundedRect: rect, xRadius: CGFloat(size) * 0.22, yRadius: CGFloat(size) * 0.22).fill()

    NSColor(red: 0.08, green: 0.10, blue: 0.13, alpha: 1).setStroke()
    let stroke = NSBezierPath()
    stroke.lineWidth = max(2, CGFloat(size) * 0.075)
    stroke.lineCapStyle = .round
    stroke.lineJoinStyle = .round

    let s = CGFloat(size)
    stroke.move(to: NSPoint(x: s * 0.34, y: s * 0.60))
    stroke.line(to: NSPoint(x: s * 0.76, y: s * 0.25))
    stroke.move(to: NSPoint(x: s * 0.66, y: s * 0.60))
    stroke.line(to: NSPoint(x: s * 0.24, y: s * 0.25))
    stroke.stroke()

    NSColor(red: 0.95, green: 0.18, blue: 0.24, alpha: 1).setStroke()
    let handles = NSBezierPath()
    handles.lineWidth = max(2, CGFloat(size) * 0.055)
    handles.appendOval(in: NSRect(x: s * 0.16, y: s * 0.62, width: s * 0.24, height: s * 0.24))
    handles.appendOval(in: NSRect(x: s * 0.60, y: s * 0.62, width: s * 0.24, height: s * 0.24))
    handles.stroke()

    NSColor(red: 0.08, green: 0.10, blue: 0.13, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: s * 0.46, y: s * 0.49, width: s * 0.08, height: s * 0.08)).fill()

    image.unlockFocus()
    return image
}

func writePNG(image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "TrimmeurIcon", code: 1)
    }

    try png.write(to: url)
}

for slot in slots {
    let image = drawIcon(size: slot.pixels)
    try writePNG(image: image, to: outputDirectory.appendingPathComponent(slot.filename))
}
SWIFT

swift "${TMP_SWIFT}" "${ICONSET_DIR}"
iconutil -c icns "${ICONSET_DIR}" -o "${ICNS_PATH}"

echo "Generated: ${ICNS_PATH}"

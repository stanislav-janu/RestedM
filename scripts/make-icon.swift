// Renders the 1024 px app icon: usage `swift scripts/make-icon.swift <output.png>`.
import AppKit

let size = 1024.0
let output = CommandLine.arguments.dropFirst().first ?? "icon.png"

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let inset = size * 0.1
let tile = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
let path = NSBezierPath(roundedRect: tile, xRadius: tile.width * 0.225, yRadius: tile.width * 0.225)

NSGraphicsContext.current?.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
shadow.shadowBlurRadius = size * 0.02
shadow.shadowOffset = NSSize(width: 0, height: -size * 0.01)
shadow.set()
NSColor.white.setFill()
path.fill()
NSGraphicsContext.current?.restoreGraphicsState()

let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.20, green: 0.74, blue: 0.86, alpha: 1),
    NSColor(calibratedRed: 0.13, green: 0.36, blue: 0.85, alpha: 1),
])!
gradient.draw(in: path, angle: -60)

let configuration = NSImage.SymbolConfiguration(pointSize: size * 0.42, weight: .semibold)
    .applying(.init(paletteColors: [.white]))
if let symbol = NSImage(systemSymbolName: "arrow.up.arrow.down", accessibilityDescription: nil)?.withSymbolConfiguration(configuration) {
    let symbolSize = symbol.size
    symbol.draw(in: NSRect(x: (size - symbolSize.width) / 2, y: (size - symbolSize.height) / 2 + size * 0.03, width: symbolSize.width, height: symbolSize.height))
}

let label = "M" as NSString
let attributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: size * 0.13, weight: .heavy),
    .foregroundColor: NSColor.white.withAlphaComponent(0.92),
]
let labelSize = label.size(withAttributes: attributes)
label.draw(at: NSPoint(x: tile.maxX - labelSize.width - size * 0.07, y: tile.minY + size * 0.045), withAttributes: attributes)

image.unlockFocus()

let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
try! bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))

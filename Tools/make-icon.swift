// Draws AppIcon.iconset. Run via `make icon`.
import AppKit

let output = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

let top = NSColor(srgbRed: 0.33, green: 0.47, blue: 0.71, alpha: 1)
let bottom = NSColor(srgbRed: 0.11, green: 0.16, blue: 0.27, alpha: 1)

func icon(size: CGFloat) -> NSImage {
    let image = NSImage(size: CGSize(width: size, height: size))
    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high

    let plate = NSRect(x: 0, y: 0, width: size, height: size).insetBy(dx: size * 0.09, dy: size * 0.09)
    let radius = plate.width * 0.2237
    NSGradient(colors: [top, bottom])?.draw(in: NSBezierPath(roundedRect: plate, xRadius: radius, yRadius: radius), angle: -90)

    let config = NSImage.SymbolConfiguration(pointSize: size * 0.44, weight: .regular)
    if let symbol = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let white = NSImage(size: symbol.size, flipped: false) { rect in
            NSColor.white.setFill()
            rect.fill()
            symbol.draw(in: rect, from: .zero, operation: .destinationIn, fraction: 1)
            return true
        }
        let box = NSRect(
            x: (size - white.size.width) / 2,
            y: (size - white.size.height) / 2,
            width: white.size.width,
            height: white.size.height
        )
        white.draw(in: box)
    }

    image.unlockFocus()
    return image
}

func write(_ image: NSImage, to name: String) throws {
    guard let tiff = image.tiffRepresentation,
          let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
    else { fatalError("cannot encode \(name)") }
    try png.write(to: output.appendingPathComponent(name))
}

for points in [16, 32, 128, 256, 512] {
    try write(icon(size: CGFloat(points)), to: "icon_\(points)x\(points).png")
    try write(icon(size: CGFloat(points * 2)), to: "icon_\(points)x\(points)@2x.png")
}

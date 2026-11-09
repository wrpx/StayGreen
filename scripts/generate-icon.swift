import Cocoa

let sizes: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png")
]

let iconsetPath = "build/AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

for (px, filename) in sizes {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: px,
        pixelsHigh: px,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let padding = CGFloat(px) * 0.08
    let rect = NSRect(x: padding, y: padding, width: CGFloat(px) - padding * 2, height: CGFloat(px) - padding * 2)
    let radius = rect.width * 0.225
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    let topColor = NSColor(calibratedRed: 0.16, green: 0.82, blue: 0.48, alpha: 1.0)
    let bottomColor = NSColor(calibratedRed: 0.05, green: 0.52, blue: 0.30, alpha: 1.0)
    let gradient = NSGradient(starting: topColor, ending: bottomColor)!
    gradient.draw(in: path, angle: -90)

    if let symbol = NSImage(systemSymbolName: "computermouse.fill", accessibilityDescription: nil) {
        let config = NSImage.SymbolConfiguration(pointSize: CGFloat(px) * 0.44, weight: .semibold)
            .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
        if let configured = symbol.withSymbolConfiguration(config) {
            let symSize = configured.size
            let symRect = NSRect(
                x: (CGFloat(px) - symSize.width) / 2.0,
                y: (CGFloat(px) - symSize.height) / 2.0,
                width: symSize.width,
                height: symSize.height
            )
            configured.draw(in: symRect)
        }
    }

    NSGraphicsContext.restoreGraphicsState()

    if let pngData = rep.representation(using: .png, properties: [:]) {
        try? pngData.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(filename)"))
    }
}

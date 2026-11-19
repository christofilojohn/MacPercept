// Builds the Percept app icon from the existing three-mode artwork.
// Keeps the emotion / focus / privacy disc, masks it to a clean circle, places it on a
// macOS-grid squircle, and adds orange viewfinder brackets for the object-detection mode.
// Run from the repo root: swift tools/generate_percept_icon.swift
import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let designDir = root.appendingPathComponent("design/app-icons")
let appIconDir = root.appendingPathComponent("src/Assets.xcassets/AppIcon.appiconset")
let sourceURL = designDir.appendingPathComponent("macvisiontools-primary-1024.png")
guard let source = NSImage(contentsOf: sourceURL) else { fatalError("Missing \(sourceURL.path)") }

// Disc geometry measured on the 1024px source (AppKit coordinates, origin bottom-left).
let discCenter = CGPoint(x: 512.5, y: 1024 - 518.5)
let discRadius: CGFloat = 462

func render(pixels: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: 1024, height: 1024)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    defer { NSGraphicsContext.restoreGraphicsState() }

    // macOS icon grid: 824pt body inside 1024 canvas, ~185pt corner radius.
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let squircle = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowBlurRadius = 24
    shadow.shadowOffset = NSSize(width: 0, height: -10)
    shadow.set()
    NSColor.black.setFill(); squircle.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    squircle.addClip()
    NSGradient(colors: [NSColor(srgbRed: 0.16, green: 0.20, blue: 0.27, alpha: 1),
                        NSColor(srgbRed: 0.06, green: 0.08, blue: 0.11, alpha: 1)])!.draw(in: body, angle: -90)
    // Soft top highlight.
    NSGradient(colors: [NSColor.white.withAlphaComponent(0.10), NSColor.white.withAlphaComponent(0)])!
        .draw(in: CGRect(x: body.minX, y: body.midY, width: body.width, height: body.height / 2), angle: -90)
    NSGraphicsContext.restoreGraphicsState()

    // Disc: scale the existing artwork so it sits inside the viewfinder.
    let targetRadius: CGFloat = 284
    let scale = targetRadius / discRadius
    let center = CGPoint(x: 512, y: 512)
    let dest = CGRect(x: center.x - discCenter.x * scale, y: center.y - discCenter.y * scale,
                      width: 1024 * scale, height: 1024 * scale)
    NSGraphicsContext.saveGraphicsState()
    let discShadow = NSShadow()
    discShadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
    discShadow.shadowBlurRadius = 30
    discShadow.shadowOffset = NSSize(width: 0, height: -12)
    discShadow.set()
    NSColor.white.setFill()
    NSBezierPath(ovalIn: CGRect(x: center.x - targetRadius, y: center.y - targetRadius, width: targetRadius * 2, height: targetRadius * 2)).fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(ovalIn: CGRect(x: center.x - targetRadius, y: center.y - targetRadius, width: targetRadius * 2, height: targetRadius * 2)).addClip()
    source.draw(in: dest, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    // Viewfinder brackets (object detection).
    let orange = NSColor(srgbRed: 1.0, green: 0.62, blue: 0.20, alpha: 1)
    let inset: CGFloat = 92, arm: CGFloat = 104, line: CGFloat = 30
    let box = body.insetBy(dx: inset, dy: inset)
    let corners: [(CGPoint, CGFloat, CGFloat)] = [
        (CGPoint(x: box.minX, y: box.maxY), 1, -1), (CGPoint(x: box.maxX, y: box.maxY), -1, -1),
        (CGPoint(x: box.minX, y: box.minY), 1, 1), (CGPoint(x: box.maxX, y: box.minY), -1, 1)
    ]
    orange.setStroke()
    for (p, dx, dy) in corners {
        let path = NSBezierPath()
        path.lineWidth = line
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.move(to: CGPoint(x: p.x, y: p.y + dy * arm))
        path.line(to: p)
        path.line(to: CGPoint(x: p.x + dx * arm, y: p.y))
        path.stroke()
    }
    return rep
}

func save(_ rep: NSBitmapImageRep, _ url: URL) throws {
    try rep.representation(using: .png, properties: [:])!.write(to: url)
}

let sizes: [(String, Int)] = [("AppIcon-16.png", 16), ("AppIcon-16@2x.png", 32), ("AppIcon-32.png", 32), ("AppIcon-32@2x.png", 64),
                              ("AppIcon-128.png", 128), ("AppIcon-128@2x.png", 256), ("AppIcon-256.png", 256),
                              ("AppIcon-256@2x.png", 512), ("AppIcon-512.png", 512), ("AppIcon-512@2x.png", 1024)]
for (name, px) in sizes { try save(render(pixels: px), appIconDir.appendingPathComponent(name)) }
try save(render(pixels: 1024), designDir.appendingPathComponent("percept-1024.png"))
try save(render(pixels: 512), designDir.appendingPathComponent("percept-512.png"))
print("Generated Percept AppIcon set.")

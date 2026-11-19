// Composes App Store (2880x1800) and website images from real panel renders.
// 1. Render panels (see ScreenshotHarness in src/MacVisionTools.swift):
//    xcodebuild -project src/MacVisionTools.xcodeproj -scheme MacVisionTools -configuration Debug \
//      -derivedDataPath build/dd CODE_SIGN_ENTITLEMENTS= ENABLE_APP_SANDBOX=NO build
//    build/dd/Build/Products/Debug/Percept.app/Contents/MacOS/Percept -PerceptRenderScreenshots YES -PerceptScreenshotDir "$PWD/design/panel-renders"
// 2. Run from repo root: swift tools/compose_real_screenshots.swift
import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sourceDir = root.appendingPathComponent("design/panel-renders", isDirectory: true)
let imageDir = root.appendingPathComponent("images", isDirectory: true)
let appStoreDir = root.appendingPathComponent("app-store/screenshots/en-US/mac-2880x1800", isDirectory: true)
let iconURL = root.appendingPathComponent("design/app-icons/percept-1024.png")

try FileManager.default.createDirectory(at: imageDir, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: appStoreDir, withIntermediateDirectories: true)

let canvas = CGSize(width: 2880, height: 1800)
let white = NSColor(calibratedWhite: 0.97, alpha: 1)
let grey = NSColor(calibratedWhite: 0.72, alpha: 1)
let orange = NSColor(srgbRed: 1.0, green: 0.62, blue: 0.20, alpha: 1)

func bitmap(_ size: CGSize, alpha: Bool = true) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height),
                               bitsPerSample: 8, samplesPerPixel: alpha ? 4 : 3, hasAlpha: alpha, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = size
    return rep
}

func draw(in rep: NSBitmapImageRep, _ block: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    block()
    NSGraphicsContext.restoreGraphicsState()
}

/// Saves without an alpha channel: App Store Connect rejects screenshots that have one.
func save(_ rep: NSBitmapImageRep, to url: URL) throws {
    let w = rep.pixelsWide, h = rep.pixelsHigh
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.draw(rep.cgImage!, in: CGRect(x: 0, y: 0, width: w, height: h))
    let flat = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    try flat.representation(using: .png, properties: [:])!.write(to: url)
}

func rounded(_ rect: CGRect, radius: CGFloat, fill: NSColor, stroke: NSColor? = nil, lineWidth: CGFloat = 2) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    fill.setFill(); path.fill()
    if let stroke { stroke.setStroke(); path.lineWidth = lineWidth; path.stroke() }
}

func text(_ value: String, rect: CGRect, size: CGFloat, weight: NSFont.Weight, color: NSColor, lineHeight: CGFloat? = nil) {
    let style = NSMutableParagraphStyle()
    style.lineBreakMode = .byWordWrapping
    if let lineHeight { style.minimumLineHeight = lineHeight; style.maximumLineHeight = lineHeight }
    NSString(string: value).draw(in: rect, withAttributes: [
        .font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color, .paragraphStyle: style
    ])
}

func background(size: CGSize, accent: NSColor, glowCenter: CGPoint) {
    NSGradient(colors: [NSColor(srgbRed: 0.05, green: 0.06, blue: 0.08, alpha: 1),
                        NSColor(srgbRed: 0.11, green: 0.13, blue: 0.16, alpha: 1)])!
        .draw(in: CGRect(origin: .zero, size: size), angle: 315)
    let r = size.height * 0.62
    NSGradient(colors: [accent.withAlphaComponent(0.30), accent.withAlphaComponent(0)])!
        .draw(in: NSBezierPath(ovalIn: CGRect(x: glowCenter.x - r, y: glowCenter.y - r, width: r * 2, height: r * 2)),
              relativeCenterPosition: .zero)
}

func tint(_ image: NSImage, _ color: NSColor) -> NSImage {
    let out = NSImage(size: image.size)
    out.lockFocus()
    image.draw(in: CGRect(origin: .zero, size: image.size))
    color.set()
    CGRect(origin: .zero, size: image.size).fill(using: .sourceAtop)
    out.unlockFocus()
    return out
}

func symbol(_ name: String, size: CGFloat, color: NSColor) -> NSImage? {
    guard let img = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: size, weight: .regular)) else { return nil }
    return tint(img, color)
}

/// Illustrative macOS menu bar strip so the panel reads as a menu bar popover.
func menuBar(size: CGSize, iconX: CGFloat, symbolName: String) {
    let bar = CGRect(x: 0, y: size.height - 56, width: size.width, height: 56)
    NSColor(calibratedWhite: 0, alpha: 0.55).setFill(); bar.fill()
    text("Thu 9:41", rect: CGRect(x: size.width - 230, y: bar.minY + 9, width: 200, height: 40), size: 28, weight: .medium, color: white)
    var x = size.width - 300
    for name in ["magnifyingglass", "battery.75percent", "wifi"] {
        if let img = symbol(name, size: 28, color: white) {
            img.draw(in: CGRect(x: x - img.size.width / 2, y: bar.midY - img.size.height / 2, width: img.size.width, height: img.size.height))
        }
        x -= 80
    }
    rounded(CGRect(x: iconX - 32, y: bar.minY + 7, width: 64, height: 42), radius: 10, fill: NSColor(calibratedWhite: 1, alpha: 0.24))
    if let img = symbol(symbolName, size: 28, color: white) {
        img.draw(in: CGRect(x: iconX - img.size.width / 2, y: bar.midY - img.size.height / 2, width: img.size.width, height: img.size.height))
    }
}

/// Draws a real panel render as a popover hanging from the menu bar icon.
func popover(_ file: String, top: CGFloat, centerX: CGFloat, scale: CGFloat) throws {
    guard let panel = NSImage(contentsOf: sourceDir.appendingPathComponent(file)) else {
        throw NSError(domain: "PerceptScreenshots", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing design/panel-renders/\(file)"])
    }
    let w = 300 * scale, h = 560 * scale
    let rect = CGRect(x: centerX - w / 2, y: top - 24 - h, width: w, height: h)
    let path = NSBezierPath(roundedRect: rect, xRadius: 28, yRadius: 28)
    let arrow = NSBezierPath()
    arrow.move(to: CGPoint(x: centerX - 28, y: rect.maxY - 1))
    arrow.line(to: CGPoint(x: centerX, y: top))
    arrow.line(to: CGPoint(x: centerX + 28, y: rect.maxY - 1))
    arrow.close()
    path.append(arrow)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.6)
    shadow.shadowBlurRadius = 60
    shadow.shadowOffset = CGSize(width: 0, height: -28)
    shadow.set()
    NSColor(calibratedWhite: 0.16, alpha: 1).setFill(); path.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: rect, xRadius: 28, yRadius: 28).addClip()
    panel.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    NSColor(calibratedWhite: 1, alpha: 0.14).setStroke(); path.lineWidth = 2; path.stroke()
}

func featureBlock(_ title: String, detail: String, x: CGFloat, y: CGFloat, width: CGFloat, color: NSColor) {
    let rect = CGRect(x: x, y: y, width: width, height: 128)
    rounded(rect, radius: 26, fill: color.withAlphaComponent(0.12), stroke: color.withAlphaComponent(0.42), lineWidth: 3)
    rounded(CGRect(x: rect.minX + 32, y: rect.midY - 24, width: 10, height: 48), radius: 5, fill: color)
    text(title, rect: CGRect(x: rect.minX + 70, y: rect.minY + 68, width: rect.width - 100, height: 42), size: 33, weight: .bold, color: white)
    text(detail, rect: CGRect(x: rect.minX + 70, y: rect.minY + 22, width: rect.width - 100, height: 40), size: 27, weight: .regular, color: grey)
}

struct Page {
    let output: String
    let panel: String
    let symbolName: String
    let eyebrow: String
    let title: String
    let subtitle: String
    let features: [(String, String)]
    let accent: NSColor
}

func compose(_ page: Page, showIcon: Bool = false) throws {
    let rep = bitmap(canvas)
    let iconX: CGFloat = 2110
    var failure: Error?
    draw(in: rep) {
        background(size: canvas, accent: page.accent, glowCenter: CGPoint(x: iconX, y: 860))
        menuBar(size: canvas, iconX: iconX, symbolName: page.symbolName)
        let left: CGFloat = 176
        var top: CGFloat = 1560
        if showIcon, let icon = NSImage(contentsOf: iconURL) {
            icon.draw(in: CGRect(x: left - 34, y: top - 250, width: 280, height: 280))
            top -= 300
        } else {
            text(page.eyebrow.uppercased(), rect: CGRect(x: left + 4, y: top - 50, width: 1100, height: 50), size: 34, weight: .heavy, color: page.accent)
            top -= 80
        }
        let titleWidth = NSString(string: page.title).size(withAttributes: [.font: NSFont.systemFont(ofSize: 120, weight: .bold)]).width
        let titleLines: CGFloat = titleWidth > 1300 ? 2 : 1
        text(page.title, rect: CGRect(x: left - 6, y: top - 132 * titleLines, width: 1330, height: 132 * titleLines + 10),
             size: 120, weight: .bold, color: white, lineHeight: 132)
        top -= 132 * titleLines + 40
        text(page.subtitle, rect: CGRect(x: left, y: top - 130, width: 1180, height: 130), size: 46, weight: .regular, color: grey, lineHeight: 62)
        top -= 200
        for (i, f) in page.features.enumerated() {
            featureBlock(f.0, detail: f.1, x: left, y: top - 128 - CGFloat(i) * 156, width: 1080,
                         color: i == 0 ? page.accent : NSColor.systemGreen)
        }
        do { try popover(page.panel, top: canvas.height - 62, centerX: iconX, scale: 2.78) } catch { failure = error }
    }
    if let failure { throw failure }
    try save(rep, to: appStoreDir.appendingPathComponent(page.output))
}

func websiteImage(panel: String, accent: NSColor, output: String) throws {
    let size = CGSize(width: 1196, height: 1268)
    let rep = bitmap(size)
    var failure: Error?
    draw(in: rep) {
        background(size: size, accent: accent, glowCenter: CGPoint(x: size.width / 2, y: size.height / 2))
        do { try popover(panel, top: size.height - 28, centerX: size.width / 2, scale: 2.12) } catch { failure = error }
    }
    if let failure { throw failure }
    try save(rep, to: imageDir.appendingPathComponent(output))
}

let pages = [
    Page(output: "01-overview.png", panel: "panel-standard.png", symbolName: "eye.circle", eyebrow: "Percept",
         title: "Percept", subtitle: "Real-time, on-device AI detection for your camera and screen, right from the menu bar.",
         features: [("Private by design", "Frames stay on this computer. No accounts, analytics, or uploads."),
                    ("Four modes in one", "Object detection, emotion cues, privacy guard, focus timer."),
                    ("Bring your own model", "Use the bundled models or pick any Core ML file.")],
         accent: orange),
    Page(output: "02-object-detection.png", panel: "panel-standard.png", symbolName: "eye.circle", eyebrow: "Standard Detection",
         title: "Detect objects live.", subtitle: "Run SSD MobileNet V2 on your camera or any screen, as a window or an overlay.",
         features: [("80 everyday object classes", "People, laptops, phones, cups, and more."),
                    ("Custom Core ML models", "Swap in your own detector in two clicks."),
                    ("Tunable", "Set confidence and frame rate from the panel.")],
         accent: orange),
    Page(output: "03-emotion-vibes.png", panel: "panel-emotion.png", symbolName: "face.smiling", eyebrow: "Emotion Vibes",
         title: "Read the room.", subtitle: "Faces are found and classified into seven expressions, entirely on device.",
         features: [("Face-first pipeline", "Only the face crop is classified, and it is never saved."),
                    ("Recent history", "A rolling strip shows how the mood shifts."),
                    ("No uploads", "Camera frames never leave the device.")],
         accent: .systemPink),
    Page(output: "04-privacy-guard.png", panel: "panel-privacy.png", symbolName: "lock.shield", eyebrow: "Privacy Guard",
         title: "Someone looking over your shoulder?", subtitle: "Percept counts the people in view and starts the screen saver when too many are watching.",
         features: [("Choose your threshold", "Act at 2, 3, 4, or 5 people."),
                    ("Counted on device", "Nothing is recorded or sent anywhere."),
                    ("Pairs with the system lock", "Require a password right after the screen saver.")],
         accent: .systemRed),
    Page(output: "05-focus-timer.png", panel: "panel-focus.png", symbolName: "timer", eyebrow: "Focus Timer",
         title: "Count the minutes that matter.", subtitle: "Head-pose tracking only counts time while you are actually looking at your work.",
         features: [("No extra model", "Built-in face tracking does the work."),
                    ("Session goals", "Aim for 15, 25, 45, or 60 minutes."),
                    ("Adjustable sensitivity", "Decide how far you can glance away.")],
         accent: .systemBlue)
]

try compose(pages[0], showIcon: true)
for page in pages.dropFirst() { try compose(page) }

try websiteImage(panel: "panel-standard.png", accent: orange, output: "standard.png")
try websiteImage(panel: "panel-emotion.png", accent: .systemPink, output: "emotion.png")
try websiteImage(panel: "panel-privacy.png", accent: .systemRed, output: "privacy.png")
try websiteImage(panel: "panel-focus.png", accent: .systemBlue, output: "focus.png")

print("Wrote \(pages.count) App Store screenshots to \(appStoreDir.path)")

import AppKit
import CoreGraphics

// Generates AppIcon.iconset for cc-times at multiple resolutions,
// then invokes iconutil to produce AppIcon.icns.
//
// Icon concept: "three orbital tracks" — concentric arcs of three theme
// colors (cyan / magenta / gold) on a dark radial background, each ending in
// a needle dot, with a center mark. Represents multi-timezone + multi-theme.

let sizes: [(name: String, px: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

func drawIcon(size S: CGFloat) -> CGImage {
    let cs = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(data: nil, width: Int(S), height: Int(S),
                        bitsPerComponent: 8, bytesPerRow: 0,
                        space: cs,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.interpolationQuality = .high

    let rect = CGRect(x: 0, y: 0, width: S, height: S)

    // ── Background: deep violet → near-black, clipped to squircle ─────────
    let colors = [CGColor(red: 0.16, green: 0.05, blue: 0.26, alpha: 1),
                  CGColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 1)] as CFArray
    let grad = CGGradient(colorsSpace: cs, colors: colors, locations: [0.0, 1.0])!
    ctx.saveGState()
    let squircle = CGPath(roundedRect: rect.insetBy(dx: S * 0.02, dy: S * 0.02),
                          cornerWidth: S * 0.2237, cornerHeight: S * 0.2237,
                          transform: nil)
    ctx.addPath(squircle)
    ctx.clip()
    ctx.drawLinearGradient(grad,
                           start: CGPoint(x: S * 0.3, y: S * 0.95),
                           end: CGPoint(x: S * 0.7, y: S * 0.05),
                           options: [])
    ctx.restoreGState()

    let center = CGPoint(x: S / 2, y: S / 2)

    // ── Three orbital arcs (theme colors), each a different sweep range ───
    let orbits: [(radius: CGFloat, startDeg: CGFloat, endDeg: CGFloat,
                  color: CGColor, width: CGFloat)] = [
        (S * 0.36, -60, 150, CGColor(red: 0.35, green: 0.85, blue: 0.95, alpha: 1), S * 0.045), // cyan
        (S * 0.26, 120, 300, CGColor(red: 1.0, green: 0.25, blue: 0.7, alpha: 1), S * 0.045),    // magenta
        (S * 0.16, 30, 210, CGColor(red: 1.0, green: 0.80, blue: 0.25, alpha: 1), S * 0.045),    // gold
    ]

    func deg2rad(_ d: CGFloat) -> CGFloat { d * .pi / 180 }

    for o in orbits {
        // Arc stroke.
        ctx.saveGState()
        ctx.setLineCap(.round)
        ctx.setStrokeColor(o.color)
        ctx.setLineWidth(o.width)
        ctx.addArc(center: center, radius: o.radius,
                   startAngle: deg2rad(o.startDeg), endAngle: deg2rad(o.endDeg),
                   clockwise: false)
        ctx.strokePath()
        ctx.restoreGState()

        // Needle dot at the arc's leading end (the "hand").
        let end = CGPoint(x: center.x + CoreGraphics.cos(deg2rad(o.endDeg)) * o.radius,
                          y: center.y + CoreGraphics.sin(deg2rad(o.endDeg)) * o.radius)
        let dotR = S * 0.032
        ctx.saveGState()
        ctx.setFillColor(CGColor(gray: 1.0, alpha: 1.0))
        ctx.fillEllipse(in: CGRect(x: end.x - dotR, y: end.y - dotR,
                                   width: dotR * 2, height: dotR * 2))
        // Glow ring in the theme color.
        ctx.setStrokeColor(o.color)
        ctx.setLineWidth(S * 0.012)
        ctx.strokeEllipse(in: CGRect(x: end.x - dotR * 1.5, y: end.y - dotR * 1.5,
                                     width: dotR * 3, height: dotR * 3))
        ctx.restoreGState()
    }

    // ── Center hub ────────────────────────────────────────────────────────
    let hubR = S * 0.05
    ctx.setFillColor(CGColor(gray: 1.0, alpha: 1.0))
    ctx.fillEllipse(in: CGRect(x: center.x - hubR, y: center.y - hubR,
                               width: hubR * 2, height: hubR * 2))

    return ctx.makeImage()!
}

// ── Render all sizes into an .iconset directory ───────────────────────────
import Foundation
let outDir = "AppIcon.iconset"
try? FileManager.default.removeItem(atPath: outDir)
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

for (name, px) in sizes {
    let img = drawIcon(size: CGFloat(px))
    let url = URL(fileURLWithPath: outDir).appendingPathComponent("\(name).png")
    let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
    print("  ✓ \(name).png (\(px)px)")
}
print("iconset written to \(outDir)/")

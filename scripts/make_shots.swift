import AppKit
import CoreGraphics
import Foundation

// Renders promotional screenshots of cc-times clock cards directly to PNG via
// CoreGraphics (offscreen). Independent of the window system, so it always
// produces clean output. Mirrors the visual style of the live app.

// ── Palette (mirrors Theme.swift) ──────────────────────────────────────────
struct BG { enum Kind { case solid(CGColor); case grad([CGColor]) }
    let kind: Kind }
struct Pal { let card: BG; let face: BG; let text: CGColor; let second: CGColor; let tick: CGFloat }

let midnight = Pal(card: .init(kind: .solid(CGColor(red:0,green:0,blue:0,alpha:0.35))),
    face: .init(kind: .solid(CGColor(red:0,green:0,blue:0,alpha:0.35))),
    text: CGColor(gray:1,alpha:1), second: CGColor(red:1,green:0,blue:0,alpha:1), tick:0.4)
let neon = Pal(card: .init(kind: .grad([CGColor(red:0.12,green:0.04,blue:0.20,alpha:1),CGColor(red:0.02,green:0.02,blue:0.06,alpha:1)])),
    face: .init(kind: .grad([CGColor(red:0.10,green:0.03,blue:0.16,alpha:1),CGColor(red:0,green:0,blue:0.04,alpha:1)])),
    text: CGColor(red:0.81,green:0.91,blue:1,alpha:1), second: CGColor(red:1,green:0.20,blue:0.75,alpha:1), tick:0.45)
let aurora = Pal(card: .init(kind: .grad([CGColor(red:0.02,green:0.16,blue:0.14,alpha:1),CGColor(red:0,green:0.03,blue:0.04,alpha:1)])),
    face: .init(kind: .grad([CGColor(red:0.02,green:0.13,blue:0.12,alpha:1),CGColor(red:0,green:0.02,blue:0.03,alpha:1)])),
    text: CGColor(red:0.83,green:1,blue:0.91,alpha:1), second: CGColor(red:0.30,green:1,blue:0.55,alpha:1), tick:0.45)
let sunset = Pal(card: .init(kind: .grad([CGColor(red:0.22,green:0.04,blue:0.12,alpha:1),CGColor(red:0.04,green:0.01,blue:0.03,alpha:1)])),
    face: .init(kind: .grad([CGColor(red:0.18,green:0.03,blue:0.10,alpha:1),CGColor(red:0.02,green:0,blue:0.02,alpha:1)])),
    text: CGColor(red:1,green:0.88,blue:0.77,alpha:1), second: CGColor(red:1,green:0.80,blue:0.20,alpha:1), tick:0.45)
let slate = Pal(card: .init(kind: .solid(CGColor(red:0.13,green:0.18,blue:0.26,alpha:0.55))),
    face: .init(kind: .solid(CGColor(red:0.13,green:0.18,blue:0.26,alpha:0.6))),
    text: CGColor(red:0.86,green:0.93,blue:1,alpha:1), second: CGColor(red:0.35,green:0.85,blue:0.95,alpha:1), tick:0.45)

// ── Drawing helpers ────────────────────────────────────────────────────────
func fillBg(_ bg: BG, in r: CGRect, ctx: CGContext) {
    switch bg.kind {
    case .solid(let c): ctx.setFillColor(c); ctx.fill(r)
    case .grad(let cs):
        let g = CGGradient(colorsSpace: ctx.colorSpace!, colors: cs as CFArray, locations: [0,1])!
        ctx.saveGState(); ctx.clip(to: r)
        ctx.drawLinearGradient(g, start: .init(x:r.minX,y:r.maxY), end: .init(x:r.maxX,y:r.minY), options: [])
        ctx.restoreGState()
    }
}

func roundRect(_ ctx: CGContext, _ r: CGRect, _ rad: CGFloat) {
    let path = CGPath(roundedRect: r, cornerWidth: rad, cornerHeight: rad, transform: nil)
    ctx.addPath(path)
}

// Draw an analog clock face centered at c with radius rad, for given h/m/s.
func drawClock(ctx: CGContext, c: CGPoint, rad: CGFloat, h:CGFloat, m:CGFloat, s:CGFloat, pal: Pal) {
    let r = CGRect(x: c.x-rad, y: c.y-rad, width: rad*2, height: rad*2)
    // face
    ctx.saveGState()
    roundRect(ctx, r.insetBy(dx:-0.5,dy:-0.5), rad) // circle approx via rounded
    ctx.addEllipse(in: r); ctx.clip()
    fillBg(pal.face, in: r, ctx: ctx)
    ctx.restoreGState()
    ctx.setStrokeColor(pal.text.copy(alpha:0.5)!); ctx.setLineWidth(2)
    ctx.strokeEllipse(in: r)
    // ticks
    for i in 0..<12 {
        let card = i%3==0
        let ang = CGFloat(i)*30*CGFloat.pi/180 - .pi/2
        let len: CGFloat = card ? 12 : 7
        ctx.setStrokeColor(pal.text.copy(alpha: card ? 0.9 : pal.tick)!)
        ctx.setLineWidth(card ? 2.5 : 1.2)
        ctx.move(to: .init(x:c.x+cos(ang)*rad, y:c.y+sin(ang)*rad))
        ctx.addLine(to: .init(x:c.x+cos(ang)*(rad-len), y:c.y+sin(ang)*(rad-len)))
        ctx.strokePath()
    }
    let hand = { (deg:CGFloat, len:CGFloat, w:CGFloat, col:CGColor) in
        let a = deg*CGFloat.pi/180
        ctx.setStrokeColor(col); ctx.setLineWidth(w); ctx.setLineCap(.round)
        ctx.move(to: c); ctx.addLine(to: .init(x:c.x+cos(a)*len, y:c.y+sin(a)*len)); ctx.strokePath()
    }
    hand((h.truncatingRemainder(dividingBy:12)+m/60)*30-90, rad*0.5, 4, pal.text.copy(alpha:0.95)!)
    hand(m*6-90, rad*0.75, 2.5, pal.text.copy(alpha:0.9)!)
    hand(s*6-90, rad*0.85, 1, pal.second.copy(alpha:0.9)!)
    ctx.setFillColor(CGColor(gray:1,alpha:1)); ctx.fillEllipse(in: CGRect(x:c.x-3,y:c.y-3,width:6,height:6))
}

func drawText(_ s: String, ctx: CGContext, at p: CGPoint, size: CGFloat, weight: CGFloat, color: CGColor, mono: Bool=false) {
    let font = CGFont(mono ? "Menlo-Bold" as CFString : "Helvetica-Bold" as CFString)
    _ = weight
    let attr: [NSAttributedString.Key: Any] = [
        .font: NSFont(name: mono ? "Menlo" : "HelveticaNeue-Medium", size: size)!,
        .foregroundColor: NSColor(cgColor: color) ?? .white]
    let str = NSAttributedString(string: s, attributes: attr)
    let line = CTLineCreateWithAttributedString(str as CFAttributedString)
    var ascent: CGFloat = 0, descent: CGFloat = 0
    let w = CTLineGetTypographicBounds(line, &ascent, &descent, nil)
    ctx.textPosition = CGPoint(x: p.x - w/2, y: p.y - (ascent-descent)/2)
    CTLineDraw(line, ctx)
}

// Draw a full card (face + city + time) for a given tz, at top-left origin o.
func drawCard(ctx: CGContext, o: CGPoint, tzID: String, pal: Pal, t: (h:CGFloat,m:CGFloat,s:CGFloat), city: String) {
    let cardW: CGFloat = 180, cardH: CGFloat = 220
    let cr: CGRect = CGRect(x: o.x, y: o.y, width: cardW, height: cardH)
    // card background
    ctx.saveGState()
    roundRect(ctx, cr, 12); ctx.clip()
    fillBg(pal.card, in: cr, ctx: ctx)
    ctx.restoreGState()
    // face
    drawClock(ctx: ctx, c: CGPoint(x: cr.midX, y: cr.maxY-70), rad: 56, h: t.h, m: t.m, s: t.s, pal: pal)
    // city chip
    let chipBg = CGColor(gray:0, alpha:0.3)
    let cityY = cr.maxY - 70 - 56 - 26
    ctx.saveGState(); roundRect(ctx, CGRect(x:cr.midX-50, y:cityY-12, width:100, height:24), 6); ctx.clip()
    ctx.setFillColor(chipBg); ctx.fill(CGRect(x:cr.midX-50,y:cityY-12,width:100,height:24)); ctx.restoreGState()
    drawText(city, ctx: ctx, at: CGPoint(x:cr.midX, y:cityY), size: 13, weight: 0.5, color: pal.text)
    // time
    let timeStr = String(format: "%02d:%02d", Int(t.h), Int(t.m))
    drawText(timeStr, ctx: ctx, at: CGPoint(x:cr.midX, y:cityY-32), size: 18, weight: 0.5, color: pal.text.copy(alpha:0.95)!, mono: true)
}

func renderRow(name: String, pals: [Pal], cities: [String], t: [(h:CGFloat,m:CGFloat,s:CGFloat)]) {
    let n = pals.count
    let gap: CGFloat = 6
    let cardW: CGFloat = 180
    let W = CGFloat(n)*cardW + CGFloat(n-1)*gap + 40
    let H: CGFloat = 260
    let cs = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(data: nil, width: Int(W*2), height: Int(H*2), bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.scaleBy(x: 2, y: 2)
    ctx.interpolationQuality = .high
    // transparent background (card shows on any wallpaper)
    for i in 0..<n {
        let o = CGPoint(x: 20 + CGFloat(i)*(cardW+gap), y: 20)
        drawCard(ctx: ctx, o: o, tzID: "", pal: pals[i], t: t[i], city: cities[i])
    }
    let img = ctx.makeImage()!
    let url = URL(fileURLWithPath: "screenshots/\(name).png")
    try? FileManager.default.createDirectory(atPath: "screenshots", withIntermediateDirectories: true)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
    print("  ✓ \(name).png (\(Int(W))x\(Int(H)))")
}

// Sample times per city (visually distinct hands)
renderRow(name: "full-midnight", pals: [midnight,midnight,midnight,midnight],
          cities: ["北京","Tokyo","London","New York"],
          t: [(10,30,15),(11,30,15),(3,30,15),(22,30,15)])
renderRow(name: "full-neonblack", pals: [neon,neon,neon,neon],
          cities: ["北京","Tokyo","London","New York"],
          t: [(10,30,15),(11,30,15),(3,30,15),(22,30,15)])
renderRow(name: "full-aurora", pals: [aurora,aurora,aurora,aurora],
          cities: ["北京","Tokyo","London","New York"],
          t: [(10,30,15),(11,30,15),(3,30,15),(22,30,15)])
renderRow(name: "full-sunset", pals: [sunset,sunset,sunset,sunset],
          cities: ["北京","Tokyo","London","New York"],
          t: [(10,30,15),(11,30,15),(3,30,15),(22,30,15)])
renderRow(name: "full-multicolor", pals: [neon,aurora,sunset,slate],
          cities: ["北京","Tokyo","London","New York"],
          t: [(10,30,15),(11,30,15),(3,30,15),(22,30,15)])
print("done")

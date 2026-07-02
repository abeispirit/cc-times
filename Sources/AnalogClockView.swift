import SwiftUI

/// Analog clock face drawn with Canvas. Hand angles are derived from the
/// hour/minute/second components of `date` interpreted in the given time zone.
/// Colors come from the supplied `palette` so the face matches its card theme.
struct AnalogClockView: View {
    let timeZone: TimeZone
    let now: Date
    let palette: Palette

    var body: some View {
        Canvas { ctx, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - Const.faceInset

            // Time components in the target time zone.
            var cal = Self.calendar
            cal.timeZone = timeZone
            let comps = cal.dateComponents([.hour, .minute, .second], from: now)
            let h = CGFloat(comps.hour ?? 0)
            let m = CGFloat(comps.minute ?? 0)
            let s = CGFloat(comps.second ?? 0)

            // Face: translucent disc (solid or gradient) + thin ring.
            let faceRect = CGRect(x: center.x - radius, y: center.y - radius,
                                  width: radius * 2, height: radius * 2)
            let facePath = Path(ellipseIn: faceRect)
            fillBackground(palette.faceBackground, in: faceRect, ctx: &ctx, path: facePath)
            ctx.stroke(facePath, with: .color(palette.textColor.opacity(Const.ringOpacity)),
                       lineWidth: Const.ringWidth)

            // 12 tick marks (cardinal ticks thicker / more opaque).
            for i in 0..<12 {
                let cardinal = i % 3 == 0
                let tickLen = cardinal ? Const.cardinalTickLen : Const.minorTickLen
                let angle = Angle.degrees(Double(i) * 30 - 90).radians
                let outer = CGPoint(x: center.x + cos(angle) * radius,
                                    y: center.y + sin(angle) * radius)
                let inner = CGPoint(x: center.x + cos(angle) * (radius - tickLen),
                                    y: center.y + sin(angle) * (radius - tickLen))
                let opacity = cardinal ? Const.cardinalTickOpacity : palette.tickOpacity
                ctx.stroke(Path { p in p.move(to: outer); p.addLine(to: inner) },
                           with: .color(palette.textColor.opacity(opacity)),
                           lineWidth: cardinal ? Const.cardinalTickWidth : Const.minorTickWidth)
            }

            // Hand angles: hour 30°/h (+minutes), minute/second 6°/unit.
            let hourAngle = (h.truncatingRemainder(dividingBy: 12) + m / 60) * 30 - 90
            let minAngle  = m * 6 - 90
            let secAngle  = s * 6 - 90

            drawHand(ctx, center, angleDeg: hourAngle, length: radius * Const.hourHandRatio,
                     width: Const.hourHandWidth, color: palette.textColor.opacity(Const.hourHandOpacity))
            drawHand(ctx, center, angleDeg: minAngle, length: radius * Const.minuteHandRatio,
                     width: Const.minuteHandWidth, color: palette.textColor.opacity(Const.minuteHandOpacity))
            drawHand(ctx, center, angleDeg: secAngle, length: radius * Const.secondHandRatio,
                     width: Const.secondHandWidth, color: palette.secondHandColor.opacity(Const.secondHandOpacity))

            // Center cap.
            let capRect = CGRect(x: center.x - Const.capRadius, y: center.y - Const.capRadius,
                                 width: Const.capRadius * 2, height: Const.capRadius * 2)
            ctx.fill(Path(ellipseIn: capRect), with: .color(palette.textColor))
        }
        .frame(width: Const.faceSize, height: Const.faceSize)
    }

    /// Shared gregorian calendar; only timeZone is reassigned per frame.
    private static let calendar = Calendar(identifier: .gregorian)

    private func drawHand(_ ctx: GraphicsContext, _ center: CGPoint,
                          angleDeg: CGFloat, length: CGFloat, width: CGFloat, color: Color) {
        let angle = Angle.degrees(Double(angleDeg)).radians
        let end = CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length)
        ctx.stroke(Path { p in p.move(to: center); p.addLine(to: end) },
                   with: .color(color), lineWidth: width)
    }

    /// Fill a path with the background style (solid color or linear gradient).
    private func fillBackground(_ bg: BackgroundStyle, in rect: CGRect,
                                ctx: inout GraphicsContext, path: Path) {
        switch bg {
        case .solid(let c):
            ctx.fill(path, with: .color(c))
        case .gradient(let stops):
            ctx.fill(path, with: .linearGradient(
                Gradient(colors: stops),
                startPoint: .init(x: rect.minX, y: rect.minY),
                endPoint: .init(x: rect.maxX, y: rect.maxY)))
        }
    }

    // MARK: - Drawing constants

    private enum Const {
        static let faceSize: CGFloat = 120
        static let faceInset: CGFloat = 4

        static let ringOpacity = 0.5
        static let ringWidth: CGFloat = 2

        static let cardinalTickLen: CGFloat = 12
        static let minorTickLen: CGFloat = 7
        static let cardinalTickOpacity = 0.9
        static let cardinalTickWidth: CGFloat = 2.5
        static let minorTickWidth: CGFloat = 1.2

        static let hourHandRatio: CGFloat = 0.5
        static let minuteHandRatio: CGFloat = 0.75
        static let secondHandRatio: CGFloat = 0.85
        static let hourHandWidth: CGFloat = 4
        static let minuteHandWidth: CGFloat = 2.5
        static let secondHandWidth: CGFloat = 1
        static let hourHandOpacity = 0.95
        static let minuteHandOpacity = 0.9
        static let secondHandOpacity = 0.9

        static let capRadius: CGFloat = 3
    }
}

import SwiftUI

/// Analog clock face drawn with Canvas. Hand angles are derived from the
/// hour/minute/second components of `date` interpreted in the given time zone.
struct AnalogClockView: View {
    let timeZone: TimeZone
    let now: Date

    var body: some View {
        Canvas { ctx, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - Const.faceInset

            // Time components in the target time zone.
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = timeZone
            let comps = cal.dateComponents([.hour, .minute, .second], from: now)
            let h = CGFloat(comps.hour ?? 0)
            let m = CGFloat(comps.minute ?? 0)
            let s = CGFloat(comps.second ?? 0)

            // Face: translucent dark disc + thin ring.
            let faceRect = CGRect(x: center.x - radius, y: center.y - radius,
                                  width: radius * 2, height: radius * 2)
            ctx.fill(Path(ellipseIn: faceRect), with: .color(.black.opacity(Const.faceOpacity)))
            ctx.stroke(Path(ellipseIn: faceRect), with: .color(.white.opacity(Const.ringOpacity)),
                       lineWidth: Const.ringWidth)

            // 12 tick marks (cardinal ticks thicker).
            for i in 0..<12 {
                let cardinal = i % 3 == 0
                let tickLen = cardinal ? Const.cardinalTickLen : Const.minorTickLen
                let angle = Angle.degrees(Double(i) * 30 - 90).radians
                let outer = CGPoint(x: center.x + cos(angle) * radius,
                                    y: center.y + sin(angle) * radius)
                let inner = CGPoint(x: center.x + cos(angle) * (radius - tickLen),
                                    y: center.y + sin(angle) * (radius - tickLen))
                ctx.stroke(Path { p in p.move(to: outer); p.addLine(to: inner) },
                           with: .color(.white.opacity(cardinal ? Const.cardinalTickOpacity : Const.minorTickOpacity)),
                           lineWidth: cardinal ? Const.cardinalTickWidth : Const.minorTickWidth)
            }

            // Hand angles: hour 30°/h (+minutes), minute/second 6°/unit.
            let hourAngle = (h.truncatingRemainder(dividingBy: 12) + m / 60) * 30 - 90
            let minAngle  = m * 6 - 90
            let secAngle  = s * 6 - 90

            drawHand(ctx, center, angleDeg: hourAngle, length: radius * Const.hourHandRatio,
                     width: Const.hourHandWidth, color: .white.opacity(Const.hourHandOpacity))
            drawHand(ctx, center, angleDeg: minAngle, length: radius * Const.minuteHandRatio,
                     width: Const.minuteHandWidth, color: .white.opacity(Const.minuteHandOpacity))
            drawHand(ctx, center, angleDeg: secAngle, length: radius * Const.secondHandRatio,
                     width: Const.secondHandWidth, color: .red.opacity(Const.secondHandOpacity))

            // Center cap.
            let capRect = CGRect(x: center.x - Const.capRadius, y: center.y - Const.capRadius,
                                 width: Const.capRadius * 2, height: Const.capRadius * 2)
            ctx.fill(Path(ellipseIn: capRect), with: .color(.white))
        }
        .frame(width: Const.faceSize, height: Const.faceSize)
    }

    private func drawHand(_ ctx: GraphicsContext, _ center: CGPoint,
                          angleDeg: CGFloat, length: CGFloat, width: CGFloat, color: Color) {
        let angle = Angle.degrees(Double(angleDeg)).radians
        let end = CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length)
        ctx.stroke(Path { p in p.move(to: center); p.addLine(to: end) },
                   with: .color(color), lineWidth: width)
    }

    // MARK: - Drawing constants

    private enum Const {
        static let faceSize: CGFloat = 120
        static let faceInset: CGFloat = 4

        static let faceOpacity = 0.35
        static let ringOpacity = 0.5
        static let ringWidth: CGFloat = 2

        static let cardinalTickLen: CGFloat = 12
        static let minorTickLen: CGFloat = 7
        static let cardinalTickOpacity = 0.9
        static let minorTickOpacity = 0.4
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

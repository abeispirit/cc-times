import SwiftUI

/// 模拟指针表盘,用 Canvas 绘制,指针角度按指定时区的时/分/秒计算
struct AnalogClockView: View {
    let timeZone: TimeZone
    let now: Date

    private let faceSize: CGFloat = 120

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 4

            // 取该时区的时分秒
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = timeZone
            let comps = cal.dateComponents([.hour, .minute, .second], from: now)
            let h = CGFloat(comps.hour ?? 0)
            let m = CGFloat(comps.minute ?? 0)
            let s = CGFloat(comps.second ?? 0)

            // —— 表盘背景(深色半透明) ——
            let faceRect = CGRect(x: center.x - radius, y: center.y - radius,
                                  width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: faceRect), with: .color(.black.opacity(0.35)))
            context.stroke(Path(ellipseIn: faceRect), with: .color(.white.opacity(0.5)), lineWidth: 2)

            // —— 12 个刻度 ——
            for i in 0..<12 {
                let angle = Angle.degrees(Double(i) * 30 - 90).radians
                let outer = CGPoint(x: center.x + cos(angle) * radius,
                                    y: center.y + sin(angle) * radius)
                let inner = CGPoint(x: center.x + cos(angle) * (radius - (i % 3 == 0 ? 12 : 7)),
                                    y: center.y + sin(angle) * (radius - (i % 3 == 0 ? 12 : 7)))
                context.stroke(Path { p in
                    p.move(to: outer); p.addLine(to: inner)
                }, with: .color(.white.opacity(i % 3 == 0 ? 0.9 : 0.4)),
                 lineWidth: i % 3 == 0 ? 2.5 : 1.2)
            }

            // 角度:时针 360/12=30°/h,分针秒针 6°/min
            let hourAngle  = (h.truncatingRemainder(dividingBy: 12) + m / 60) * 30 - 90
            let minAngle   = m * 6 - 90
            let secAngle   = s * 6 - 90

            // —— 指针 ——
            drawHand(context: context, center: center, angleDeg: hourAngle,
                     length: radius * 0.5, width: 4, color: .white.opacity(0.95))
            drawHand(context: context, center: center, angleDeg: minAngle,
                     length: radius * 0.75, width: 2.5, color: .white.opacity(0.9))
            drawHand(context: context, center: center, angleDeg: secAngle,
                     length: radius * 0.85, width: 1, color: .red.opacity(0.9))

            // —— 中心点 ——
            context.fill(Path(ellipseIn: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6)),
                         with: .color(.white))
        }
        .frame(width: faceSize, height: faceSize)
    }

    private func drawHand(context: GraphicsContext, center: CGPoint,
                          angleDeg: CGFloat, length: CGFloat, width: CGFloat, color: Color) {
        let angle = Angle.degrees(Double(angleDeg)).radians
        let end = CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length)
        context.stroke(Path { p in p.move(to: center); p.addLine(to: end) },
                       with: .color(color), lineWidth: width)
    }
}

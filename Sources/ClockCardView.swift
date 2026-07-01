import SwiftUI

/// 单个时钟卡片。
/// 完整模式:纵向 [表盘] / [城市名] / [数字时间]
/// 简版模式:横向 [城市名] [数字时间],无表盘,更紧凑
struct ClockCardView: View {
    let config: ClockConfig
    let now: Date
    let compact: Bool

    var body: some View {
        if compact {
            compactBody
        } else {
            fullBody
        }
    }

    /// 完整模式
    private var fullBody: some View {
        VStack(spacing: 8) {
            AnalogClockView(timeZone: config.timeZone, now: now)

            Text(config.city)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 6))

            Text(digitalString)
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.95))
                .padding(.horizontal, 10)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 6))
        }
        .padding(10)
    }

    /// 简版模式:仅城市名 + 数字时间,横排一行
    private var compactBody: some View {
        HStack(spacing: 8) {
            Text(config.city)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Text(digitalString)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.95))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 6))
    }

    /// 24 小时制数字时间,按该时区格式化
    private var digitalString: String {
        let fmt = DateFormatter()
        fmt.timeZone = config.timeZone
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: now)
    }
}

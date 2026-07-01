import SwiftUI

/// A single clock card.
/// - Full mode: vertical stack of analog face / city name / digital time.
/// - Compact mode: horizontal row of city name + digital time (no face).
/// All colors come from `palette` so the card matches its assigned theme.
struct ClockCardView: View {
    let config: ClockConfig
    let now: Date
    let compact: Bool
    let language: Language
    let palette: Palette

    var body: some View {
        if compact {
            compactBody
        } else {
            fullBody
        }
    }

    // MARK: - Layouts

    private var fullBody: some View {
        VStack(spacing: Const.stackSpacing) {
            AnalogClockView(timeZone: config.timeZone, now: now, palette: palette)
            chip(text: cityName, size: Const.cityFontSize, weight: .semibold, design: .rounded)
            chip(text: digitalString, size: Const.timeFontSizeFull, weight: .medium, design: .monospaced)
        }
        .padding(Const.cardPadding)
        .background {
            cardBackground.clipShape(RoundedRectangle(cornerRadius: Const.cardRadius))
        }
    }

    private var compactBody: some View {
        HStack(spacing: Const.compactSpacing) {
            chip(text: cityName, size: Const.cityFontSize, weight: .semibold, design: .rounded)
            chip(text: digitalString, size: Const.timeFontSizeCompact, weight: .medium, design: .monospaced)
        }
        .padding(.horizontal, Const.compactHPad)
        .padding(.vertical, Const.compactVPad)
        .background {
            cardBackground.clipShape(RoundedRectangle(cornerRadius: Const.cardRadius))
        }
    }

    // MARK: - Helpers

    /// Small rounded "chip" behind text. A subtle dark scrim keeps text legible
    /// over both solid and gradient card backgrounds.
    private func chip(text: String, size: CGFloat, weight: Font.Weight, design: Font.Design) -> some View {
        Text(text)
            .font(.system(size: size, weight: weight, design: design))
            .foregroundColor(palette.textColor.opacity(palette.textOpacity))
            .padding(.horizontal, Const.chipHPad)
            .padding(.vertical, Const.chipVPad)
            .background {
                palette.chipBackground.clipShape(RoundedRectangle(cornerRadius: Const.chipRadius))
            }
    }

    /// Card background resolving solid vs gradient.
    @ViewBuilder
    private var cardBackground: some View {
        switch palette.cardBackground {
        case .solid(let c):
            c
        case .gradient(let stops):
            LinearGradient(colors: stops,
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    /// City name (localized) followed by its UTC offset, e.g. "北京 UTC+8".
    private var cityName: String {
        let name = CityRegistry.localizedName(for: config.timeZoneID, language)
        let offset = City.formatUTCOffset(seconds: config.timeZone.secondsFromGMT())
        return "\(name) \(offset)"
    }

    /// 24-hour digital time in the card's time zone. Formatter is cached
    /// (TimelineView redraws every second, so re-creating it would waste work).
    private var digitalString: String {
        Self.formatter.timeZone = config.timeZone
        return Self.formatter.string(from: now)
    }

    private static var formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private enum Const {
        static let stackSpacing: CGFloat = 8
        static let cardPadding: CGFloat = 10
        static let compactSpacing: CGFloat = 8
        static let compactHPad: CGFloat = 10
        static let compactVPad: CGFloat = 5

        static let cityFontSize: CGFloat = 13
        static let timeFontSizeFull: CGFloat = 18
        static let timeFontSizeCompact: CGFloat = 15
        static let chipHPad: CGFloat = 10
        static let chipVPad: CGFloat = 3

        static let cardRadius: CGFloat = 12
        static let chipRadius: CGFloat = 6
    }
}

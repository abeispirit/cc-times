import SwiftUI

/// A single clock card.
/// - Full mode: vertical stack of analog face / city name / digital time.
/// - Compact mode: horizontal row of city name + digital time (no face).
struct ClockCardView: View {
    let config: ClockConfig
    let now: Date
    let compact: Bool
    let language: Language

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
            AnalogClockView(timeZone: config.timeZone, now: now)
            chip(text: cityName, size: Const.cityFontSize, weight: .semibold, design: .rounded)
            chip(text: digitalString, size: Const.timeFontSizeFull, weight: .medium, design: .monospaced)
        }
        .padding(Const.cardPadding)
    }

    private var compactBody: some View {
        HStack(spacing: Const.compactSpacing) {
            chip(text: cityName, size: Const.cityFontSize, weight: .semibold, design: .rounded)
            chip(text: digitalString, size: Const.timeFontSizeCompact, weight: .medium, design: .monospaced)
        }
        .padding(.horizontal, Const.compactHPad)
        .padding(.vertical, Const.compactVPad)
        .background(Const.cardBg, in: RoundedRectangle(cornerRadius: Const.cardRadius))
    }

    // MARK: - Helpers

    /// Small rounded "chip" with the translucent dark background used for both
    /// the city name and the digital time, to keep styles consistent.
    private func chip(text: String, size: CGFloat, weight: Font.Weight, design: Font.Design) -> some View {
        Text(text)
            .font(.system(size: size, weight: weight, design: design))
            .foregroundColor(textColor)
            .padding(.horizontal, Const.chipHPad)
            .padding(.vertical, Const.chipVPad)
            .background(Const.cardBg, in: RoundedRectangle(cornerRadius: Const.cardRadius))
    }

    /// City name in the currently selected language.
    private var cityName: String {
        CityRegistry.localizedName(for: config.timeZoneID, language)
    }

    /// 24-hour digital time in the card's time zone. Formatter is cached
    /// (TimelineView redraws every second, so re-creating it would waste work).
    private var digitalString: String {
        Self.formatter.timeZone = config.timeZone
        return Self.formatter.string(from: now)
    }

    private var textColor: Color { .white.opacity(Const.textOpacity) }
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

        static let cardBgOpacity = 0.35
        static var cardBg: Color { Color.black.opacity(cardBgOpacity) }
        static let cardRadius: CGFloat = 6
        static let textOpacity = 0.95
    }
}

import SwiftUI

/// A single clock card.
/// - Full mode: analog face + a single info row `[city date weekday time]`.
/// - Compact mode: just the info row, no face.
///
/// The info row is one line: `北京 7月2日 周五 10:47` / `Beijing Jul 2 Fri 10:47`.
/// Date and weekday follow the clock's own time zone (New York may be yesterday).
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
            infoRow(timeSize: Const.timeFontSizeFull)
        }
        .padding(Const.cardPadding)
        .background {
            cardBackground.clipShape(RoundedRectangle(cornerRadius: Const.cardRadius))
        }
    }

    private var compactBody: some View {
        infoRow(timeSize: Const.timeFontSizeCompact)
            .padding(.horizontal, Const.compactHPad)
            .padding(.vertical, Const.compactVPad)
            .background {
                cardBackground.clipShape(RoundedRectangle(cornerRadius: Const.cardRadius))
            }
    }

    /// The single info row: city · date weekday · time, all in one line, with
    /// a uniform font size. Text sits directly on the card background (no extra
    /// chip layer) so solid themes (Sand/Slate) and gradients show cleanly.
    private func infoRow(timeSize: CGFloat) -> some View {
        HStack(spacing: Const.rowSpacing) {
            Text(cityName)
                .font(.system(size: timeSize, weight: .semibold, design: .rounded))
            Text(dateWeekString)
                .font(.system(size: timeSize, weight: .medium, design: .monospaced))
            Text(timeString)
                .font(.system(size: timeSize, weight: .medium, design: .monospaced))
        }
        .foregroundColor(palette.textColor.opacity(palette.textOpacity))
        .padding(.horizontal, Const.chipHPad)
        .padding(.vertical, Const.chipVPad)
    }

    // MARK: - Helpers

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

    /// City name in the currently selected language.
    private var cityName: String {
        CityRegistry.localizedName(for: config.timeZoneID, language)
    }

    /// Date + weekday in the clock's time zone, e.g. "7月2日 周五" / "Jul 2 Fri".
    private var dateWeekString: String {
        Self.dateFormatter(for: config.timeZoneID, language)?.string(from: now) ?? ""
    }

    /// 24-hour time in the card's time zone.
    private var timeString: String {
        Self.timeFormatter(for: config.timeZoneID)?.string(from: now) ?? "--:--"
    }

    // MARK: - Cached formatters (immutable after build, safe to share)

    private static var timeFormatters: [String: DateFormatter] = [:]
    private static var dateFormatters: [String: DateFormatter] = [:]

    private static func timeFormatter(for tzID: String) -> DateFormatter? {
        if let cached = timeFormatters[tzID] { return cached }
        guard let tz = TimeZone(identifier: tzID) else { return nil }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = tz
        timeFormatters[tzID] = f
        return f
    }

    private static func dateFormatter(for tzID: String, _ lang: Language) -> DateFormatter? {
        let key = tzID + "|" + lang.rawValue
        if let cached = dateFormatters[key] { return cached }
        guard let tz = TimeZone(identifier: tzID) else { return nil }
        let f = DateFormatter()
        f.locale = lang == .zh ? Locale(identifier: "zh_CN") : Locale(identifier: "en_US_POSIX")
        f.dateFormat = lang == .zh ? "M月d日 EEE" : "MMM d EEE"
        f.timeZone = tz
        dateFormatters[key] = f
        return f
    }

    private enum Const {
        static let stackSpacing: CGFloat = 8
        static let cardPadding: CGFloat = 10
        static let compactHPad: CGFloat = 10
        static let compactVPad: CGFloat = 5

        static let rowSpacing: CGFloat = 6
        static let timeFontSizeFull: CGFloat = 18
        static let timeFontSizeCompact: CGFloat = 15
        static let chipHPad: CGFloat = 10
        static let chipVPad: CGFloat = 3

        static let cardRadius: CGFloat = 12
        static let chipRadius: CGFloat = 6
    }
}

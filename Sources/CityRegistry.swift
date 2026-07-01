import Foundation

/// A curated world city with its IANA time zone identifier and localized names.
/// Time calculations always use `tzID` (the single source of truth);
/// `nameEN` / `nameZH` are only for display.
struct City: Equatable {
    let tzID: String      // IANA time zone identifier, e.g. "Asia/Shanghai"
    let nameEN: String    // English display name
    let nameZH: String    // Chinese display name

    /// Localized display name for the given language.
    func localizedName(_ lang: Language) -> String {
        lang == .zh ? nameZH : nameEN
    }

    /// UTC offset string for this city, e.g. "UTC+8", "UTC-5", "UTC+5:30".
    /// Computed live from the system time zone database so it reflects the
    /// real current offset (including DST when in effect).
    var utcOffsetString: String {
        guard let tz = TimeZone(identifier: tzID) else { return "UTC" }
        let seconds = tz.secondsFromGMT()
        return City.formatUTCOffset(seconds: seconds)
    }

    /// Display name with trailing UTC offset, e.g. "Beijing (UTC+8)".
    func label(_ lang: Language) -> String {
        "\(localizedName(lang)) (\(utcOffsetString))"
    }

    /// Format a GMT offset in seconds into a "UTC±H[:MM]" string.
    static func formatUTCOffset(seconds: Int) -> String {
        let sign = seconds >= 0 ? "+" : "-"
        let abs = abs(seconds)
        let h = abs / 3600
        let m = (abs % 3600) / 60
        if m == 0 {
            return "UTC\(sign)\(h)"
        }
        return "UTC\(sign)\(h):\(String(format: "%02d", m))"
    }
}

/// Registry of 24 well-known world cities, exactly one per whole-hour UTC
/// offset from UTC-11 to UTC+12. Each is a recognizable city so users can
/// find a zone by its offset. Ordered west → east.
enum CityRegistry {

    /// The 24 most recognizable world cities, exactly one per whole-hour UTC
    /// offset from UTC-11 to UTC+12. Each is a well-known city so users can
    /// quickly locate a zone by its offset. Ordered west → east.
    static let cities: [City] = [
        City(tzID: "Pacific/Pago_Pago",    nameEN: "Pago Pago",    nameZH: "帕果帕果"),   // UTC-11
        City(tzID: "Pacific/Honolulu",     nameEN: "Honolulu",     nameZH: "檀香山"),     // UTC-10
        City(tzID: "America/Anchorage",    nameEN: "Anchorage",    nameZH: "安克雷奇"),   // UTC-9
        City(tzID: "America/Los_Angeles",  nameEN: "Los Angeles",  nameZH: "洛杉矶"),     // UTC-8
        City(tzID: "America/Denver",       nameEN: "Denver",       nameZH: "丹佛"),       // UTC-7
        City(tzID: "America/Chicago",      nameEN: "Chicago",      nameZH: "芝加哥"),     // UTC-6
        City(tzID: "America/New_York",     nameEN: "New York",     nameZH: "纽约"),       // UTC-5
        City(tzID: "America/Santiago",     nameEN: "Santiago",     nameZH: "圣地亚哥"),   // UTC-4
        City(tzID: "America/Sao_Paulo",    nameEN: "São Paulo",    nameZH: "圣保罗"),     // UTC-3
        City(tzID: "Atlantic/South_Georgia", nameEN: "South Georgia", nameZH: "南乔治亚"), // UTC-2
        City(tzID: "Atlantic/Cape_Verde",  nameEN: "Cape Verde",   nameZH: "佛得角"),     // UTC-1
        City(tzID: "Europe/London",        nameEN: "London",       nameZH: "伦敦"),       // UTC+0
        City(tzID: "Europe/Paris",         nameEN: "Paris",        nameZH: "巴黎"),       // UTC+1
        City(tzID: "Africa/Cairo",         nameEN: "Cairo",        nameZH: "开罗"),       // UTC+2
        City(tzID: "Europe/Moscow",        nameEN: "Moscow",       nameZH: "莫斯科"),     // UTC+3
        City(tzID: "Asia/Dubai",           nameEN: "Dubai",        nameZH: "迪拜"),       // UTC+4
        City(tzID: "Asia/Karachi",         nameEN: "Karachi",      nameZH: "卡拉奇"),     // UTC+5
        City(tzID: "Asia/Dhaka",           nameEN: "Dhaka",        nameZH: "达卡"),       // UTC+6
        City(tzID: "Asia/Bangkok",         nameEN: "Bangkok",      nameZH: "曼谷"),       // UTC+7
        City(tzID: "Asia/Shanghai",        nameEN: "Beijing",      nameZH: "北京"),       // UTC+8
        City(tzID: "Asia/Tokyo",           nameEN: "Tokyo",        nameZH: "东京"),       // UTC+9
        City(tzID: "Australia/Sydney",     nameEN: "Sydney",       nameZH: "悉尼"),       // UTC+10
        City(tzID: "Pacific/Noumea",       nameEN: "Nouméa",       nameZH: "努美阿"),     // UTC+11
        City(tzID: "Pacific/Auckland",     nameEN: "Auckland",     nameZH: "奥克兰"),     // UTC+12
    ]

    /// Look up the localized name for a time zone id. Falls back to a derived
    /// English name (last path component of the id) when not in the registry.
    static func localizedName(for tzID: String, _ lang: Language) -> String {
        if let city = cities.first(where: { $0.tzID == tzID }) {
            return city.localizedName(lang)
        }
        let raw = tzID.split(separator: "/").last.map(String.init) ?? tzID
        return raw.replacingOccurrences(of: "_", with: " ")
    }
}

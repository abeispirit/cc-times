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
}

/// Registry of curated cities offered in the "Add Time Zone" menu and used to
/// resolve display names from a persisted IANA identifier.
enum CityRegistry {

    /// Curated list. Order defines menu order.
    /// Note: Beijing shares the "Asia/Shanghai" IANA id with Shanghai
    /// (mainland China has a single zone); both are listed so users can pick
    /// the display label they prefer.
    static let cities: [City] = [
        City(tzID: "Asia/Shanghai",         nameEN: "Beijing",      nameZH: "北京"),
        City(tzID: "Asia/Shanghai",         nameEN: "Shanghai",     nameZH: "上海"),
        City(tzID: "Asia/Tokyo",            nameEN: "Tokyo",        nameZH: "东京"),
        City(tzID: "Asia/Seoul",            nameEN: "Seoul",        nameZH: "首尔"),
        City(tzID: "Asia/Singapore",        nameEN: "Singapore",    nameZH: "新加坡"),
        City(tzID: "Asia/Dubai",            nameEN: "Dubai",        nameZH: "迪拜"),
        City(tzID: "Europe/London",         nameEN: "London",       nameZH: "伦敦"),
        City(tzID: "Europe/Paris",          nameEN: "Paris",        nameZH: "巴黎"),
        City(tzID: "Europe/Berlin",         nameEN: "Berlin",       nameZH: "柏林"),
        City(tzID: "Europe/Moscow",         nameEN: "Moscow",       nameZH: "莫斯科"),
        City(tzID: "America/New_York",      nameEN: "New York",     nameZH: "纽约"),
        City(tzID: "America/Los_Angeles",   nameEN: "Los Angeles",  nameZH: "洛杉矶"),
        City(tzID: "America/Chicago",       nameEN: "Chicago",      nameZH: "芝加哥"),
        City(tzID: "Australia/Sydney",      nameEN: "Sydney",       nameZH: "悉尼"),
    ]

    /// Look up the localized name for a time zone id. Falls back to a derived
    /// English name (last path component of the id) when not in the registry.
    static func localizedName(for tzID: String, _ lang: Language) -> String {
        if let city = cities.first(where: { $0.tzID == tzID }) {
            return city.localizedName(lang)
        }
        // Fallback: derive an English label from the IANA id.
        let raw = tzID.split(separator: "/").last.map(String.init) ?? tzID
        return raw.replacingOccurrences(of: "_", with: " ")
    }
}

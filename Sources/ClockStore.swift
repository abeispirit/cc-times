import Foundation

/// A single clock entry. Only the IANA time zone id is persisted; the display
/// name is resolved at render time via `CityRegistry` so it follows the
/// currently selected language. `themeOverride` optionally pins a per-clock
/// theme (nil = follow the global theme). A legacy `city` field (an English
/// city name) is migrated to `timeZoneID` on decode for old data files.
struct ClockConfig: Codable, Identifiable, Equatable {
    var id: UUID
    var timeZoneID: String
    var themeOverride: String?   // Theme.rawValue, nil = follow global

    enum CodingKeys: String, CodingKey {
        case id, timeZoneID, themeOverride, city
    }

    init(id: UUID = UUID(), timeZoneID: String, themeOverride: String? = nil) {
        self.id = id
        self.timeZoneID = timeZoneID
        self.themeOverride = themeOverride
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        // Newer files carry timeZoneID; old files only had a `city` name.
        if let tz = try? c.decode(String.self, forKey: .timeZoneID) {
            self.timeZoneID = tz
        } else if let city = try? c.decode(String.self, forKey: .city),
                  let migrated = ClockConfig.migrateLegacyCity(city) {
            self.timeZoneID = migrated
        } else {
            throw DecodingError.keyNotFound(CodingKeys.timeZoneID,
                .init(codingPath: decoder.codingPath,
                      debugDescription: "Missing timeZoneID and unmappable city"))
        }
        self.themeOverride = try? c.decode(String.self, forKey: .themeOverride)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(timeZoneID, forKey: .timeZoneID)
        try c.encodeIfPresent(themeOverride, forKey: .themeOverride)
    }

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneID) ?? .current
    }

    /// Map a legacy English city name (old data format) to an IANA id.
    private static func migrateLegacyCity(_ city: String) -> String? {
        CityRegistry.cities.first { $0.nameEN == city }?.tzID
    }

    /// Effective theme for this clock: its override if set, else the global one.
    func effectiveTheme(global: String) -> Theme {
        if let raw = themeOverride, let t = Theme(rawValue: raw) {
            return t
        }
        return Theme(rawValue: global) ?? .midnight
    }
}

/// Persisted user settings (compact mode, opacity, always-on-top, theme).
struct AppSettings: Codable {
    var compact: Bool = false
    var opacity: Double = 1.0
    var alwaysOnTop: Bool = true
    var theme: String = Theme.midnight.rawValue
}

/// Holds the clock list and user settings, persisting both to JSON under
/// `~/.config/mtimes/`.
final class ClockStore: ObservableObject {
    @Published var clocks: [ClockConfig] { didSet { scheduleSaveClocks() } }
    @Published var settings: AppSettings { didSet { scheduleSaveSettings() } }

    private let clocksURL: URL
    private let settingsURL: URL
    // Debounce pending disk writes so rapid changes (e.g. dragging an opacity
    // slider) don't hit the filesystem on every value.
    private var clocksSaveWork: DispatchWorkItem?
    private var settingsSaveWork: DispatchWorkItem?

    init() {
        let dir = URL(fileURLWithPath: NSHomeDirectory() + "/.config/mtimes/")
        self.clocksURL = dir.appendingPathComponent("clocks.json")
        self.settingsURL = dir.appendingPathComponent("settings.json")
        self.clocks = ClockStore.loadClocks(url: clocksURL)
        self.settings = ClockStore.loadSettings(url: settingsURL)
    }

    deinit {
        clocksSaveWork?.cancel()
        settingsSaveWork?.cancel()
    }

    // MARK: - Clocks

    private static func loadClocks(url: URL) -> [ClockConfig] {
        // First launch: no file yet → seed defaults. Otherwise honor what's on
        // disk, including a legitimately empty list (user removed all clocks).
        guard FileManager.default.fileExists(atPath: url.path) else {
            return [
                ClockConfig(timeZoneID: "Asia/Shanghai"),
                ClockConfig(timeZoneID: "America/New_York"),
            ]
        }
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([ClockConfig].self, from: data) else {
            // Corrupt file → fall back to defaults rather than crash.
            return [
                ClockConfig(timeZoneID: "Asia/Shanghai"),
                ClockConfig(timeZoneID: "America/New_York"),
            ]
        }
        return decoded
    }

    private func scheduleSaveClocks() {
        clocksSaveWork?.cancel()
        let snapshot = clocks
        let url = clocksURL
        let work = DispatchWorkItem { Self.persist(snapshot, to: url) }
        clocksSaveWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    // MARK: - Settings

    private static func loadSettings(url: URL) -> AppSettings {
        guard let data = try? Data(contentsOf: url),
              let s = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return s
    }

    private func scheduleSaveSettings() {
        settingsSaveWork?.cancel()
        let snapshot = settings
        let url = settingsURL
        let work = DispatchWorkItem { Self.persist(snapshot, to: url) }
        settingsSaveWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    // MARK: - Helpers

    private static func persist<T: Encodable>(_ value: T, to url: URL) {
        let dir = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(value) {
            try? data.write(to: url, options: .atomic)
        }
    }

    func add(timeZoneID: String) {
        clocks.append(ClockConfig(timeZoneID: timeZoneID))
    }

    func remove(_ id: UUID) {
        clocks.removeAll { $0.id == id }
    }
}

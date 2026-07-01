import Foundation

/// A single clock entry. Only the IANA time zone id is persisted; the display
/// name is resolved at render time via `CityRegistry` so it follows the
/// currently selected language. A legacy `city` field is still decoded (and
/// ignored) so older `clocks.json` files keep working.
struct ClockConfig: Codable, Identifiable, Equatable {
    var id: UUID
    var timeZoneID: String

    enum CodingKeys: String, CodingKey {
        case id
        case timeZoneID
        // Legacy key kept for backward compatibility with old data files.
        case city
    }

    init(id: UUID = UUID(), timeZoneID: String) {
        self.id = id
        self.timeZoneID = timeZoneID
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        self.timeZoneID = try c.decode(String.self, forKey: .timeZoneID)
        // `city` is intentionally ignored.
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(timeZoneID, forKey: .timeZoneID)
    }

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneID) ?? .current
    }
}

/// Persisted user settings (compact mode, opacity, always-on-top).
struct AppSettings: Codable {
    var compact: Bool = false
    var opacity: Double = 1.0
    var alwaysOnTop: Bool = true
}

/// Holds the clock list and user settings, persisting both to JSON under
/// `~/.config/mtimes/`.
final class ClockStore: ObservableObject {
    @Published var clocks: [ClockConfig] { didSet { saveClocks() } }
    @Published var settings: AppSettings { didSet { saveSettings() } }

    private let clocksURL: URL
    private let settingsURL: URL

    init() {
        let dir = URL(fileURLWithPath: NSHomeDirectory() + "/.config/mtimes/")
        self.clocksURL = dir.appendingPathComponent("clocks.json")
        self.settingsURL = dir.appendingPathComponent("settings.json")
        self.clocks = ClockStore.loadClocks(url: clocksURL)
        self.settings = ClockStore.loadSettings(url: settingsURL)
    }

    // MARK: - Clocks

    private static func loadClocks(url: URL) -> [ClockConfig] {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([ClockConfig].self, from: data),
              !decoded.isEmpty else {
            return [
                ClockConfig(timeZoneID: "Asia/Shanghai"),
                ClockConfig(timeZoneID: "America/New_York"),
            ]
        }
        return decoded
    }

    private func saveClocks() {
        persist(clocks, to: clocksURL)
    }

    // MARK: - Settings

    private static func loadSettings(url: URL) -> AppSettings {
        guard let data = try? Data(contentsOf: url),
              let s = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return s
    }

    private func saveSettings() {
        persist(settings, to: settingsURL)
    }

    // MARK: - Helpers

    private func persist<T: Encodable>(_ value: T, to url: URL) {
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

import Foundation

/// 单个时钟配置
struct ClockConfig: Codable, Identifiable, Equatable {
    var id: UUID
    var city: String           // 展示名,如 "Beijing"
    var timeZoneID: String     // IANA 时区,如 "Asia/Shanghai"

    init(id: UUID = UUID(), city: String, timeZoneID: String) {
        self.id = id
        self.city = city
        self.timeZoneID = timeZoneID
    }

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneID) ?? .current
    }
}

/// 时区列表 + 显示设置,可增删,持久化到 JSON
final class ClockStore: ObservableObject {
    @Published var clocks: [ClockConfig] {
        didSet { save() }
    }
    /// 简版模式:仅显示数字时间 + 地区,不画表盘
    @Published var compact: Bool {
        didSet { saveSettings() }
    }

    private let url: URL
    private let settingsURL: URL

    init() {
        let home = NSHomeDirectory()
        let dir = home + "/.config/mtimes/"
        self.url = URL(fileURLWithPath: dir + "clocks.json")
        self.settingsURL = URL(fileURLWithPath: dir + "settings.json")
        self.clocks = ClockStore.load(url: url)
        self.compact = ClockStore.loadCompact(url: settingsURL)
    }

    private static func load(url: URL) -> [ClockConfig] {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([ClockConfig].self, from: data),
              !decoded.isEmpty else {
            // 默认 2 个时区
            return [
                ClockConfig(city: "Beijing",   timeZoneID: "Asia/Shanghai"),
                ClockConfig(city: "New York",  timeZoneID: "America/New_York"),
            ]
        }
        return decoded
    }

    private func save() {
        let dir = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(clocks) {
            try? data.write(to: url, options: .atomic)
        }
    }

    private static func loadCompact(url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let v = obj["compact"] as? Bool else { return false }
        return v
    }

    private func saveSettings() {
        let dir = settingsURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let payload = ["compact": compact]
        if let data = try? JSONSerialization.data(withJSONObject: payload) {
            try? data.write(to: settingsURL, options: .atomic)
        }
    }

    func add(_ city: String, _ tzID: String) {
        clocks.append(ClockConfig(city: city, timeZoneID: tzID))
    }

    func remove(at offsets: IndexSet) {
        clocks.remove(atOffsets: offsets)
    }

    func remove(_ id: UUID) {
        clocks.removeAll { $0.id == id }
    }
}

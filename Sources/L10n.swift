import Foundation
import Combine

/// Supported display languages.
enum Language: String, CaseIterable, Codable {
    case zh
    case en

    /// User-facing label shown in the language submenu.
    var displayName: String {
        switch self {
        case .zh: return "中文"
        case .en: return "English"
        }
    }

    /// Pick the best match for the user's system preferred languages.
    /// Falls back to English when no supported language is detected.
    static func detect() -> Language {
        for id in Locale.preferredLanguages {
            let normalized = id.lowercased()
            if normalized.hasPrefix("zh") { return .zh }
            if normalized.hasPrefix("en") { return .en }
        }
        return .en
    }
}

/// String keys used for localized UI text. Centralized so typos surface at compile time.
enum L10nKey {
    // Submenu headers
    static let removeTimezone = "remove_timezone"
    static let addTimezone = "add_timezone"
    static let opacity = "opacity"
    static let language = "language"

    // Toggle items
    static let alwaysOnTop = "always_on_top"
    static let compactMode = "compact_mode"

    // Actions
    static let quit = "quit"
}

/// Internationalization core: holds the current language and serves translations.
/// Pure in-memory dictionaries (no .strings / bundle) so runtime switching is instant
/// and there is zero resource-packaging burden for the swiftc command-line build.
final class L10n: ObservableObject {
    @Published var language: Language {
        didSet { defaults.set(language.rawValue, forKey: Self.key) }
    }

    static let shared = L10n()

    private let defaults = UserDefaults.standard
    private static let key = "mtimes.language"

    private init() {
        if let raw = defaults.string(forKey: Self.key),
           let lang = Language(rawValue: raw) {
            language = lang
        } else {
            language = Language.detect()
        }
    }

    /// Switch language at runtime; SwiftUI views observing this object re-render.
    func setLanguage(_ lang: Language) {
        language = lang
    }

    /// Translate a key for the current language; returns the key itself if missing.
    func tr(_ key: String) -> String {
        let table = language == .zh ? L10n.tableZH : L10n.tableEN
        return table[key] ?? key
    }

    // MARK: - String tables

    private static let tableEN: [String: String] = [
        L10nKey.removeTimezone: "Remove Time Zone",
        L10nKey.addTimezone:    "Add Time Zone",
        L10nKey.opacity:        "Window Opacity",
        L10nKey.language:       "Language",
        L10nKey.alwaysOnTop:    "Always on Top",
        L10nKey.compactMode:    "Compact (digits only)",
        L10nKey.quit:           "Quit",
    ]

    private static let tableZH: [String: String] = [
        L10nKey.removeTimezone: "删除时区",
        L10nKey.addTimezone:    "添加时区",
        L10nKey.opacity:        "窗口透明度",
        L10nKey.language:       "语言",
        L10nKey.alwaysOnTop:    "常驻置顶",
        L10nKey.compactMode:    "简版(仅数字)",
        L10nKey.quit:           "退出",
    ]
}

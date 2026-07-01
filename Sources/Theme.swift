import SwiftUI

/// Background style for a card or clock face: either a flat color or a
/// multi-stop linear gradient.
enum BackgroundStyle {
    case solid(Color)
    case gradient([Color])   // top-leading → bottom-trailing
}

/// A complete color set for one clock card. Every theme resolves to a Palette
/// so views never branch on theme names — they just read these properties.
struct Palette {
    let cardBackground: BackgroundStyle
    let faceBackground: BackgroundStyle
    let textColor: Color        // city name, digital time, hands, ticks
    let secondHandColor: Color
    let tickOpacity: Double     // multiplier for non-cardinal ticks
    let textOpacity: Double     // for secondary text (digital time)

    /// Solid dark translucent, used as the chip background behind text so text
    /// stays readable over both solid and gradient card backgrounds.
    var chipBackground: Color {
        // A subtle scrim derived from textColor keeps contrast on any theme.
        Color.black.opacity(0.28)
    }
}

/// The six built-in color themes. `rawValue` is the persisted id.
enum Theme: String, CaseIterable {
    case midnight
    case slate
    case sand
    case neonBlack
    case aurora
    case sunset

    var displayNameEN: String {
        switch self {
        case .midnight: return "Midnight"
        case .slate:    return "Slate"
        case .sand:     return "Sand"
        case .neonBlack: return "Neon Black"
        case .aurora:   return "Aurora"
        case .sunset:   return "Sunset"
        }
    }

    var displayNameZH: String {
        switch self {
        case .midnight: return "午夜"
        case .slate:    return "石板"
        case .sand:     return "沙色"
        case .neonBlack: return "五彩斑斓的黑"
        case .aurora:   return "极光"
        case .sunset:   return "日落"
        }
    }

    func displayName(_ lang: Language) -> String {
        lang == .zh ? displayNameZH : displayNameEN
    }

    var isGradient: Bool {
        self == .neonBlack || self == .aurora || self == .sunset
    }

    var palette: Palette {
        switch self {
        // ── Basic solid themes ──────────────────────────────────────
        case .midnight:
            return Palette(
                cardBackground: .solid(Color.black.opacity(0.35)),
                faceBackground: .solid(Color.black.opacity(0.35)),
                textColor: .white, secondHandColor: .red,
                tickOpacity: 0.4, textOpacity: 0.95)
        case .slate:
            let base = Color(red: 0.13, green: 0.18, blue: 0.26)
            return Palette(
                cardBackground: .solid(base.opacity(0.55)),
                faceBackground: .solid(base.opacity(0.6)),
                textColor: Color(red: 0.86, green: 0.93, blue: 1.0),  // icy white-blue
                secondHandColor: Color(red: 0.35, green: 0.85, blue: 0.95),  // cyan
                tickOpacity: 0.45, textOpacity: 0.95)
        case .sand:
            let base = Color(red: 0.95, green: 0.90, blue: 0.80)     // warm cream
            return Palette(
                cardBackground: .solid(base.opacity(0.85)),
                faceBackground: .solid(base.opacity(0.9)),
                textColor: Color(red: 0.27, green: 0.18, blue: 0.10),  // deep brown
                secondHandColor: Color(red: 0.90, green: 0.45, blue: 0.15),  // orange
                tickOpacity: 0.5, textOpacity: 0.85)

        // ── Neon gradient themes (dark background) ──────────────────
        case .neonBlack:
            // "五彩斑斓的黑": deep purple → near-black with a violet glow.
            return Palette(
                cardBackground: .gradient([
                    Color(red: 0.12, green: 0.04, blue: 0.20),   // deep violet
                    Color(red: 0.02, green: 0.02, blue: 0.06),   // near black
                ]),
                faceBackground: .gradient([
                    Color(red: 0.10, green: 0.03, blue: 0.16),
                    Color(red: 0.0, green: 0.0, blue: 0.04),
                ]),
                textColor: Color(red: 0.81, green: 0.91, blue: 1.0),  // pale icy blue
                secondHandColor: Color(red: 1.0, green: 0.20, blue: 0.75),  // magenta
                tickOpacity: 0.45, textOpacity: 0.95)
        case .aurora:
            // Aurora: deep teal-green → black.
            return Palette(
                cardBackground: .gradient([
                    Color(red: 0.02, green: 0.16, blue: 0.14),   // deep teal
                    Color(red: 0.0, green: 0.03, blue: 0.04),    // black
                ]),
                faceBackground: .gradient([
                    Color(red: 0.02, green: 0.13, blue: 0.12),
                    Color(red: 0.0, green: 0.02, blue: 0.03),
                ]),
                textColor: Color(red: 0.83, green: 1.0, blue: 0.91),  // mint white
                secondHandColor: Color(red: 0.30, green: 1.0, blue: 0.55),  // emerald
                tickOpacity: 0.45, textOpacity: 0.95)
        case .sunset:
            // Sunset: deep magenta-red → black.
            return Palette(
                cardBackground: .gradient([
                    Color(red: 0.22, green: 0.04, blue: 0.12),   // wine
                    Color(red: 0.04, green: 0.01, blue: 0.03),   // black
                ]),
                faceBackground: .gradient([
                    Color(red: 0.18, green: 0.03, blue: 0.10),
                    Color(red: 0.02, green: 0.0, blue: 0.02),
                ]),
                textColor: Color(red: 1.0, green: 0.88, blue: 0.77),  // warm peach white
                secondHandColor: Color(red: 1.0, green: 0.80, blue: 0.20),  // gold
                tickOpacity: 0.45, textOpacity: 0.95)
        }
    }
}

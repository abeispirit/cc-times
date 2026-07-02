import AppKit
import SwiftUI

/// Creates and configures the main window: transparent, borderless, floating
/// (so it can be dragged; the `.desktop` level cannot receive mouse events on
/// macOS, so floating is used instead). Right-click offers time-zone
/// add/remove, opacity, language, and display-mode actions.
final class WindowManager {
    private var window: DraggableDesktopWindow?

    func show(store: ClockStore, l10n: L10n) {
        let rootView = ClockRowView(store: store, l10n: l10n)
        let hosting = NSHostingController(rootView: rootView)

        let initial = WindowMetrics.size(forCompact: store.settings.compact,
                                         clockCount: store.clocks.count)
        let w = DraggableDesktopWindow(contentRect: initial, store: store, l10n: l10n)
        w.contentViewController = hosting

        // Transparent borderless floating window (draggable).
        w.styleMask = .borderless
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = false
        w.level = store.settings.alwaysOnTop ? .floating : .normal
        w.collectionBehavior = [.canJoinAllSpaces, .stationary]
        w.isMovable = true
        w.isMovableByWindowBackground = true
        w.alphaValue = CGFloat(store.settings.opacity)

        // Size: width follows the number of clocks so compact content is never
        // clipped; full mode uses the fixed size.
        let lockedSize = WindowMetrics.size(forCompact: store.settings.compact,
                                            clockCount: store.clocks.count)
        w.setContentSize(lockedSize)
        w.contentMinSize = WindowMetrics.minSize
        let mainScreen = NSScreen.screens.first { $0.frame.origin == .zero }
            ?? NSScreen.main ?? NSScreen.screens.first
        if let screen = mainScreen {
            let vf = screen.visibleFrame
            w.setFrameOrigin(NSPoint(x: vf.midX - lockedSize.width / 2,
                                     y: vf.maxY - lockedSize.height - WindowMetrics.topMargin))
        } else {
            w.center()
        }

        w.makeKeyAndOrderFront(nil)
        self.window = w
    }
}

/// Window subclass that builds the right-click context menu and keeps window
/// state (opacity, always-on-top) in sync with the persisted settings.
/// Dragging is handled by the system via `isMovableByWindowBackground`.
final class DraggableDesktopWindow: NSWindow {
    private let store: ClockStore
    private let l10n: L10n

    init(contentRect: NSSize, store: ClockStore, l10n: L10n) {
        self.store = store
        self.l10n = l10n
        super.init(contentRect: NSRect(x: 0, y: 0, width: contentRect.width, height: contentRect.height),
                   styleMask: .borderless, backing: .buffered, defer: false)
    }

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()
        menu.addItem(buildRemoveSubmenu())
        menu.addItem(buildAddSubmenu())
        menu.addItem(NSMenuItem.separator())
        menu.addItem(buildThemeSubmenu())
        menu.addItem(buildPerClockColorSubmenu())
        menu.addItem(buildOpacitySubmenu())
        menu.addItem(buildLanguageSubmenu())
        menu.addItem(toggleItem(title: l10n.tr(L10nKey.alwaysOnTop),
                                isOn: store.settings.alwaysOnTop,
                                action: #selector(toggleOnTop)))
        menu.addItem(toggleItem(title: l10n.tr(L10nKey.compactMode),
                                isOn: store.settings.compact,
                                action: #selector(toggleCompact)))
        menu.addItem(NSMenuItem.separator())
        let quit = NSMenuItem(title: l10n.tr(L10nKey.quit),
                              action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        NSMenu.popUpContextMenu(menu, with: event, for: self.contentView ?? NSView())
    }

    // MARK: - Menu builders

    /// "Remove time zone" submenu: one entry per current clock.
    private func buildRemoveSubmenu() -> NSMenuItem {
        let sub = NSMenu(title: l10n.tr(L10nKey.removeTimezone))
        for c in store.clocks {
            let name = CityRegistry.localizedName(for: c.timeZoneID, l10n.language)
            let item = NSMenuItem(title: name, action: #selector(removeClock(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = c.id
            sub.addItem(item)
        }
        let parent = NSMenuItem(title: l10n.tr(L10nKey.removeTimezone), action: nil, keyEquivalent: "")
        parent.submenu = sub
        return parent
    }

    /// "Add time zone" submenu: the curated city list from CityRegistry.
    /// Each item shows "City (UTC±X)" so the offset is visible while choosing.
    private func buildAddSubmenu() -> NSMenuItem {
        let sub = NSMenu(title: l10n.tr(L10nKey.addTimezone))
        for city in CityRegistry.cities {
            let item = NSMenuItem(title: city.label(l10n.language),
                                  action: #selector(addClock(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = city.tzID
            sub.addItem(item)
        }
        let parent = NSMenuItem(title: l10n.tr(L10nKey.addTimezone), action: nil, keyEquivalent: "")
        parent.submenu = sub
        return parent
    }

    /// "Window opacity" submenu: preset levels with a checkmark on the current.
    private func buildOpacitySubmenu() -> NSMenuItem {
        let sub = NSMenu(title: l10n.tr(L10nKey.opacity))
        for ratio in [1.0, 0.8, 0.6, 0.45, 0.3] {
            let item = NSMenuItem(title: "\(Int(ratio * 100))%",
                                  action: #selector(setOpacity(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = ratio
            if abs(ratio - store.settings.opacity) < 0.001 { item.state = .on }
            sub.addItem(item)
        }
        let parent = NSMenuItem(title: l10n.tr(L10nKey.opacity), action: nil, keyEquivalent: "")
        parent.submenu = sub
        return parent
    }

    /// "Language" submenu: one entry per supported language.
    private func buildLanguageSubmenu() -> NSMenuItem {
        let sub = NSMenu(title: l10n.tr(L10nKey.language))
        for lang in Language.allCases {
            let item = NSMenuItem(title: lang.displayName,
                                  action: #selector(setLanguage(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = lang.rawValue
            if lang == l10n.language { item.state = .on }
            sub.addItem(item)
        }
        let parent = NSMenuItem(title: l10n.tr(L10nKey.language), action: nil, keyEquivalent: "")
        parent.submenu = sub
        return parent
    }

    /// Helper: a toggle-style item with a leading check mark when on.
    private func toggleItem(title: String, isOn: Bool, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: (isOn ? "✓ " : "  ") + title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    /// "Theme" submenu: pick the global default theme.
    private func buildThemeSubmenu() -> NSMenuItem {
        let sub = NSMenu(title: l10n.tr(L10nKey.theme))
        for theme in Theme.allCases {
            let item = NSMenuItem(title: theme.displayName(l10n.language),
                                  action: #selector(setGlobalTheme(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = theme.rawValue
            if theme.rawValue == store.settings.theme { item.state = .on }
            sub.addItem(item)
        }
        let parent = NSMenuItem(title: l10n.tr(L10nKey.theme), action: nil, keyEquivalent: "")
        parent.submenu = sub
        return parent
    }

    /// "Per-clock color" submenu: for each current clock, choose its own theme
    /// (or follow the global one).
    private func buildPerClockColorSubmenu() -> NSMenuItem {
        let sub = NSMenu(title: l10n.tr(L10nKey.perClockColor))
        // One sub-submenu per clock.
        for c in store.clocks {
            let name = CityRegistry.localizedName(for: c.timeZoneID, l10n.language)
            let clockSub = NSMenu(title: name)
            // "Follow global" option.
            let follow = NSMenuItem(title: l10n.tr(L10nKey.followGlobal),
                                    action: #selector(setClockTheme(_:)), keyEquivalent: "")
            follow.target = self
            follow.representedObject = ["id": c.id.uuidString, "theme": NSNull()]
            if c.themeOverride == nil { follow.state = .on }
            clockSub.addItem(follow)
            clockSub.addItem(NSMenuItem.separator())
            for theme in Theme.allCases {
                let item = NSMenuItem(title: theme.displayName(l10n.language),
                                      action: #selector(setClockTheme(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = ["id": c.id.uuidString, "theme": theme.rawValue]
                if c.themeOverride == theme.rawValue { item.state = .on }
                clockSub.addItem(item)
            }
            let parent = NSMenuItem(title: name, action: nil, keyEquivalent: "")
            parent.submenu = clockSub
            sub.addItem(parent)
        }
        let root = NSMenuItem(title: l10n.tr(L10nKey.perClockColor), action: nil, keyEquivalent: "")
        root.submenu = sub
        return root
    }

    // MARK: - Actions

    @objc private func setOpacity(_ sender: NSMenuItem) {
        guard let r = sender.representedObject as? Double else { return }
        store.settings.opacity = r
        alphaValue = CGFloat(r)
    }

    @objc private func toggleOnTop() {
        store.settings.alwaysOnTop.toggle()
        level = store.settings.alwaysOnTop ? .floating : .normal
    }

    @objc private func toggleCompact() {
        store.settings.compact.toggle()
        // Resize, keeping the horizontal center fixed.
        let newSize = WindowMetrics.size(forCompact: store.settings.compact)
        var f = frame
        let oldCenterX = f.midX
        f.size = newSize
        f.origin.x = oldCenterX - newSize.width / 2
        setFrame(f, display: true, animate: false)
    }

    @objc private func setLanguage(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let lang = Language(rawValue: raw) else { return }
        l10n.setLanguage(lang)
    }

    /// Set the global default theme.
    @objc private func setGlobalTheme(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              Theme(rawValue: raw) != nil else { return }   // reject invalid ids
        store.settings.theme = raw
    }

    /// Set (or clear) a single clock's theme override.
    /// representedObject = ["id": uuidString, "theme": raw | NSNull].
    @objc private func setClockTheme(_ sender: NSMenuItem) {
        guard let dict = sender.representedObject as? [String: Any],
              let idStr = dict["id"] as? String,
              let id = UUID(uuidString: idStr) else { return }
        let themeRaw = dict["theme"]
        let override = (themeRaw is NSNull) ? nil : (themeRaw as? String)
        if let idx = store.clocks.firstIndex(where: { $0.id == id }) {
            store.clocks[idx].themeOverride = override
        }
    }

    @objc private func addClock(_ sender: NSMenuItem) {
        guard let tzID = sender.representedObject as? String else { return }
        store.add(timeZoneID: tzID)
        resyncSize()
    }

    @objc private func removeClock(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID else { return }
        store.remove(id)
        resyncSize()
    }

    /// Resize the window to fit current content (compact width follows the
    /// clock count), keeping the horizontal center fixed.
    private func resyncSize() {
        let newSize = WindowMetrics.size(forCompact: store.settings.compact,
                                         clockCount: store.clocks.count)
        var f = frame
        let oldCenterX = f.midX
        f.size = newSize
        f.origin.x = oldCenterX - newSize.width / 2
        setFrame(f, display: true, animate: false)
    }
}

/// Window sizing, kept in one place so full/compact sizes stay in sync.
/// Compact width scales with the number of clocks (fixedSize content must not
/// be clipped by a locked window frame).
enum WindowMetrics {
    static let minSize = NSSize(width: 200, height: 50)
    static let topMargin: CGFloat = 30

    static let fullSize = NSSize(width: 760, height: 240)
    static let compactHeight: CGFloat = 60
    /// Approximate per-clock width in compact mode (city + time chip + padding).
    static let compactClockWidth: CGFloat = 170
    static let compactBaseWidth: CGFloat = 40

    static func size(forCompact compact: Bool, clockCount: Int = 2) -> NSSize {
        if compact {
            let w = compactBaseWidth + compactClockWidth * CGFloat(max(clockCount, 1))
            return NSSize(width: w, height: compactHeight)
        }
        return fullSize
    }
}

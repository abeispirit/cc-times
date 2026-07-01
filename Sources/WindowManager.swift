import AppKit
import SwiftUI

/// 配置主窗口:透明、无边框、悬浮层(可拖动),右键可切到贴桌面层、增删时区。
///
/// 为什么默认用 .floating 而非 .desktop:
/// macOS 对壁纸层(.desktop)窗口不派发鼠标事件,无法拖动。
/// .floating 层可正常拖动、可跨屏;右键可切到 .desktop 沉浸展示(切回时拖动暂停)。
final class WindowManager {
    private var window: DraggableDesktopWindow?

    func show(store: ClockStore) {
        let rootView = ClockRowView(store: store)
        let hosting = NSHostingController(rootView: rootView)

        let w = DraggableDesktopWindow(
            contentRect: NSSize(width: 760, height: 240),
            store: store
        )
        w.contentViewController = hosting

        // —— 透明无边框悬浮窗口(可拖动) ——
        w.styleMask = .borderless
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = false
        w.level = .floating
        w.collectionBehavior = [.canJoinAllSpaces, .stationary]
        w.isMovable = true
        w.isMovableByWindowBackground = true

        // 定位到主屏顶部居中
        let mainScreen = NSScreen.screens.first { $0.frame.origin == .zero } ?? NSScreen.main ?? NSScreen.screens.first
        if let screen = mainScreen {
            let vf = screen.visibleFrame
            let winSize = w.frame.size
            let x = vf.midX - winSize.width / 2
            let y = vf.maxY - winSize.height - 30
            w.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            w.center()
        }

        w.makeKeyAndOrderFront(nil)
        self.window = w
    }
}

/// 右键菜单(增删时区/切换层级)的窗口。拖动由系统 isMovableByWindowBackground 接管。
final class DraggableDesktopWindow: NSWindow {
    private let store: ClockStore

    init(contentRect: NSSize, store: ClockStore) {
        self.store = store
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: contentRect.width, height: contentRect.height),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
    }

    // 右键:增/删时区、透明度、退出
    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()

        // —— 删除当前时区(子菜单,父项必须有标题才显示) ——
        let del = NSMenu()
        del.title = "删除时区"
        for c in store.clocks {
            let item = NSMenuItem(title: c.city, action: #selector(removeClock(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = c.id
            del.addItem(item)
        }
        let delItem = NSMenuItem(title: "删除时区", action: nil, keyEquivalent: "")
        delItem.submenu = del
        menu.addItem(delItem)

        // —— 添加时区(子菜单) ——
        let add = NSMenu()
        add.title = "添加时区"
        let presets: [(String, String)] = [
            ("Beijing", "Asia/Shanghai"),
            ("Shanghai", "Asia/Shanghai"),
            ("Tokyo", "Asia/Tokyo"),
            ("Seoul", "Asia/Seoul"),
            ("Singapore", "Asia/Singapore"),
            ("London", "Europe/London"),
            ("Paris", "Europe/Paris"),
            ("Berlin", "Europe/Berlin"),
            ("Moscow", "Europe/Moscow"),
            ("Dubai", "Asia/Dubai"),
            ("New York", "America/New_York"),
            ("Los Angeles", "America/Los_Angeles"),
            ("Chicago", "America/Chicago"),
            ("Sydney", "Australia/Sydney"),
        ]
        for (city, tz) in presets {
            let item = NSMenuItem(title: city, action: #selector(addClock(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = [city, tz]
            add.addItem(item)
        }
        let addItem = NSMenuItem(title: "添加时区", action: nil, keyEquivalent: "")
        addItem.submenu = add
        menu.addItem(addItem)

        menu.addItem(NSMenuItem.separator())

        // —— 窗口透明度(替代"贴桌面",用降低透明度减轻遮挡) ——
        let op = NSMenu()
        op.title = "窗口透明度"
        for ratio in [1.0, 0.8, 0.6, 0.45, 0.3] {
            let pct = Int(ratio * 100)
            let item = NSMenuItem(title: "\(pct)%", action: #selector(setOpacity(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = ratio
            if abs(ratio - currentOpacity) < 0.001 { item.state = .on }
            op.addItem(item)
        }
        let opItem = NSMenuItem(title: "窗口透明度", action: nil, keyEquivalent: "")
        opItem.submenu = op
        menu.addItem(opItem)

        // —— 置顶开关 ——
        let onTop = NSMenuItem(title: isAlwaysOnTop ? "✓ 常驻置顶" : "  常驻置顶",
                               action: #selector(toggleOnTop), keyEquivalent: "")
        onTop.target = self
        menu.addItem(onTop)

        // —— 简版/完整 切换 ——
        let modeTitle = store.compact ? "✓ 简版(仅数字)" : "  简版(仅数字)"
        let mode = NSMenuItem(title: modeTitle, action: #selector(toggleCompact), keyEquivalent: "")
        mode.target = self
        menu.addItem(mode)

        menu.addItem(NSMenuItem.separator())
        let quit = NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        NSMenu.popUpContextMenu(menu, with: event, for: self.contentView ?? NSView())
    }

    // MARK: - 菜单动作

    /// 当前整体透明度
    private var currentOpacity: Double = 1.0
    /// 是否常驻置顶(.floating)。关掉则降到 .normal,会被其他窗口遮挡。
    private var isAlwaysOnTop = true

    @objc private func setOpacity(_ sender: NSMenuItem) {
        guard let r = sender.representedObject as? Double else { return }
        currentOpacity = r
        // 用 alphaValue 控制整体透明度
        self.alphaValue = CGFloat(r)
    }

    @objc private func toggleOnTop() {
        isAlwaysOnTop.toggle()
        self.level = isAlwaysOnTop ? .floating : .normal
    }

    @objc private func toggleCompact() {
        store.compact.toggle()
        // 切换后卡片尺寸变化,按当前内容重新紧贴窗口
        self.setContentSize(self.contentView?.fittingSize ?? self.frame.size)
    }

    @objc private func addClock(_ sender: NSMenuItem) {
        guard let arr = sender.representedObject as? [String], arr.count == 2 else { return }
        store.add(arr[0], arr[1])
    }

    @objc private func removeClock(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID else { return }
        store.remove(id)
    }
}

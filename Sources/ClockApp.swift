import AppKit
import SwiftUI

@main
struct ClockApp: App {
    // 用 AppDelegateAdaptor 拿到 NSWindow 做透明/桌面层配置
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowManager: WindowManager?
    private let store = ClockStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 隐藏 dock 图标(纯桌面 widget 风格);如需保留 dock 把下行注释掉
        NSApp.setActivationPolicy(.accessory)

        let wm = WindowManager()
        wm.show(store: store)
        windowManager = wm
    }
}

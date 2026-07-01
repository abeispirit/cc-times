import AppKit
import SwiftUI

/// App entry point. Uses an AppDelegate adaptor to configure the borderless
/// transparent window via AppKit (SwiftUI alone cannot set window level /
/// transparency / collection behavior).
@main
struct ClockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowManager: WindowManager?
    private let store = ClockStore()
    private let l10n = L10n.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as a background-style app: no Dock icon or menu bar
        // (pure desktop widget). Comment out to keep the Dock icon.
        NSApp.setActivationPolicy(.accessory)

        let wm = WindowManager()
        wm.show(store: store, l10n: l10n)
        windowManager = wm
    }
}

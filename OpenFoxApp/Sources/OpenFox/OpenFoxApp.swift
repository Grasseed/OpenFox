import SwiftUI
import AppKit

@main
struct OpenFoxApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var botManager = BotManager.shared
    @StateObject private var locale = LocaleManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(botManager)
                .environmentObject(locale)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1000, height: 680)

        MenuBarExtra("OpenFox", systemImage: botManager.isRunning ? "bolt.fill" : "bolt.slash") {
            MenuBarView()
                .environmentObject(botManager)
                .environmentObject(locale)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Force the main window to appear on every launch
        DispatchQueue.main.async {
            if let window = NSApp.windows.first(where: { $0.canBecomeKey && $0.className != "NSStatusBarWindow" }) {
                window.makeKeyAndOrderFront(nil)
            } else {
                NSApp.sendAction(Selector(("_openMainWindow:")), to: nil, from: nil)
            }
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        BotManager.shared.stopBot()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in NSApp.windows {
                if window.canBecomeKey {
                    window.makeKeyAndOrderFront(nil)
                    return true
                }
            }
        }
        return true
    }
}

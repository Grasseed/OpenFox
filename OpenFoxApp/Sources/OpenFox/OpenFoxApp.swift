import SwiftUI

@main
struct OpenFoxApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var botManager = BotManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(botManager)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1000, height: 680)

        MenuBarExtra("OpenFox", systemImage: botManager.isRunning ? "bolt.fill" : "bolt.slash") {
            MenuBarView()
                .environmentObject(botManager)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        BotManager.shared.stopBot()
    }
}

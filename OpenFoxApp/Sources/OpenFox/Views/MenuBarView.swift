import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var botManager: BotManager

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Circle()
                    .fill(botManager.isRunning ? Color.green : Color.secondary.opacity(0.4))
                    .frame(width: 8, height: 8)
                Text(botManager.isRunning ? "Running" : "Stopped")
                    .font(.system(size: 13, weight: .medium))
            }

            Divider()

            if botManager.isRunning {
                HStack {
                    Text("Uptime:")
                        .foregroundStyle(.secondary)
                    Text(botManager.uptime)
                }
                .font(.system(size: 12))

                HStack {
                    Text("Tokens:")
                        .foregroundStyle(.secondary)
                    Text(botManager.usageStats.formattedTotal)
                }
                .font(.system(size: 12))

                Divider()
            }

            Button(botManager.isRunning ? "Stop Bot" : "Start Bot") {
                if botManager.isRunning {
                    botManager.stopBot()
                } else {
                    botManager.startBot()
                }
            }
            .keyboardShortcut(botManager.isRunning ? "s" : "r")

            if botManager.isRunning {
                Button("Restart Bot") {
                    botManager.restartBot()
                }
            }

            Divider()

            Button("Open Window") {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.title.isEmpty || $0.title == "OpenFox" }) {
                    window.makeKeyAndOrderFront(nil)
                } else {
                    NSApp.windows.first?.makeKeyAndOrderFront(nil)
                }
            }
            .keyboardShortcut("o")

            Divider()

            Button("Quit OpenFox") {
                botManager.stopBot()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NSApp.terminate(nil)
                }
            }
            .keyboardShortcut("q")
        }
    }
}

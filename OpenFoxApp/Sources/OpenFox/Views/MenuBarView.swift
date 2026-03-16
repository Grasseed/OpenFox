import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var botManager: BotManager
    @EnvironmentObject var locale: LocaleManager

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Circle()
                    .fill(botManager.isRunning ? Color.green : Color.secondary.opacity(0.4))
                    .frame(width: 8, height: 8)
                Text(botManager.isRunning ? locale.t(.statusRunning) : locale.t(.statusStopped))
                    .font(.system(size: 13, weight: .medium))
            }

            Divider()

            if botManager.isRunning {
                HStack {
                    Text(locale.t(.menuUptime)).foregroundStyle(.secondary)
                    Text(botManager.uptime)
                }.font(.system(size: 12))

                HStack {
                    Text(locale.t(.menuTokens)).foregroundStyle(.secondary)
                    Text(botManager.usageStats.formattedTotal)
                }.font(.system(size: 12))

                Divider()
            }

            Button(botManager.isRunning ? locale.t(.menuStop) : locale.t(.menuStart)) {
                if botManager.isRunning { botManager.stopBot() } else { botManager.startBot() }
            }

            if botManager.isRunning {
                Button(locale.t(.menuRestart)) { botManager.restartBot() }
            }

            Divider()

            Button(locale.t(.menuOpenWindow)) {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows.first(where: { $0.canBecomeKey })?.makeKeyAndOrderFront(nil)
            }

            Divider()

            Button(locale.t(.menuQuit)) {
                botManager.stopBot()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { NSApp.terminate(nil) }
            }
        }
    }
}

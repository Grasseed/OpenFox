import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var botManager: BotManager
    @State private var uptimeRefresh = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dashboard")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Monitor and control your OpenFox bot")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.bottom, 8)

                // Status card
                StatusCard(botManager: botManager)
                    .id(uptimeRefresh)

                // Quick stats
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    StatCard(
                        title: "Total Tokens",
                        value: botManager.usageStats.formattedTotal,
                        icon: "number.circle.fill",
                        color: .blue
                    )
                    StatCard(
                        title: "Input",
                        value: botManager.usageStats.formattedInput,
                        icon: "arrow.down.circle.fill",
                        color: .green
                    )
                    StatCard(
                        title: "Output",
                        value: botManager.usageStats.formattedOutput,
                        icon: "arrow.up.circle.fill",
                        color: .purple
                    )
                    StatCard(
                        title: "Sessions",
                        value: "\(botManager.usageStats.activeSessions)",
                        icon: "person.2.fill",
                        color: .orange
                    )
                }

                // Quick actions
                HStack(spacing: 16) {
                    QuickActionCard(
                        title: "Start Bot",
                        subtitle: "Launch polling mode",
                        icon: "play.circle.fill",
                        color: .green,
                        disabled: botManager.isRunning
                    ) {
                        botManager.startBot()
                    }

                    QuickActionCard(
                        title: "Stop Bot",
                        subtitle: "Gracefully shut down",
                        icon: "stop.circle.fill",
                        color: .red,
                        disabled: !botManager.isRunning
                    ) {
                        botManager.stopBot()
                    }

                    QuickActionCard(
                        title: "Reload Config",
                        subtitle: "Re-read .env file",
                        icon: "arrow.triangle.2.circlepath.circle.fill",
                        color: .blue
                    ) {
                        botManager.loadConfig()
                        botManager.loadState()
                    }
                }

                // Recent logs preview
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Recent Activity", systemImage: "text.justify.left")
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Text("\(botManager.logs.count) entries")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    if botManager.logs.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "text.page.slash")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.secondary.opacity(0.5))
                                Text("No activity yet")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 24)
                            Spacer()
                        }
                    } else {
                        VStack(spacing: 1) {
                            ForEach(botManager.logs.suffix(5).reversed()) { entry in
                                LogRow(entry: entry, compact: true)
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.background)
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                )

                Spacer(minLength: 20)
            }
            .padding(32)
        }
        .onReceive(timer) { _ in
            if botManager.isRunning {
                uptimeRefresh.toggle()
            }
        }
    }
}

struct StatusCard: View {
    @ObservedObject var botManager: BotManager

    var body: some View {
        HStack(spacing: 20) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(
                        botManager.isRunning
                            ? LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [.secondary.opacity(0.3), .secondary.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: botManager.isRunning ? .green.opacity(0.4) : .clear, radius: 16)

                Image(systemName: botManager.isRunning ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(botManager.isRunning ? "Bot is Running" : "Bot is Stopped")
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                if botManager.isRunning {
                    HStack(spacing: 16) {
                        Label(botManager.uptime, systemImage: "clock")
                        if !botManager.config.opencodeModel.isEmpty {
                            Label(botManager.config.opencodeModel, systemImage: "cpu")
                        }
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                } else {
                    Text("Press Start to launch the Telegram bot")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Main action button
            Button {
                if botManager.isRunning {
                    botManager.stopBot()
                } else {
                    botManager.startBot()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: botManager.isRunning ? "stop.fill" : "play.fill")
                    Text(botManager.isRunning ? "Stop" : "Start")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: botManager.isRunning
                                    ? [.red, .red.opacity(0.8)]
                                    : [.green, .green.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: botManager.isRunning ? .red.opacity(0.3) : .green.opacity(0.3), radius: 8, y: 2)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var disabled: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(disabled ? .secondary.opacity(0.4) : color)

                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(disabled ? .secondary : .primary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.background)
                    .shadow(color: .black.opacity(isHovered && !disabled ? 0.1 : 0.05), radius: isHovered && !disabled ? 12 : 8, y: 2)
            )
            .scaleEffect(isHovered && !disabled ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

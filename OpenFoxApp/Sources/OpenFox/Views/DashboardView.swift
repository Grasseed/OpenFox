import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var botManager: BotManager
    @EnvironmentObject var locale: LocaleManager
    @State private var tick = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(locale.t(.dashTitle))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text(locale.t(.dashSubtitle))
                            .font(.system(size: 14)).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.bottom, 8)

                StatusCard()

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                    StatCard(title: locale.t(.usageTotalTokens), value: botManager.usageStats.formattedTotal, icon: "number.circle.fill", color: .blue)
                    StatCard(title: locale.t(.usageInput), value: botManager.usageStats.formattedInput, icon: "arrow.down.circle.fill", color: .green)
                    StatCard(title: locale.t(.usageOutput), value: botManager.usageStats.formattedOutput, icon: "arrow.up.circle.fill", color: .purple)
                    StatCard(title: locale.t(.usageSessions), value: "\(botManager.usageStats.activeSessions)", icon: "person.2.fill", color: .orange)
                }

                HStack(spacing: 16) {
                    QuickActionCard(title: locale.t(.btnStart), subtitle: locale.t(.dashStartSub), icon: "play.circle.fill", color: .green, disabled: botManager.isRunning) { botManager.startBot() }
                    QuickActionCard(title: locale.t(.btnStop), subtitle: locale.t(.dashStopSub), icon: "stop.circle.fill", color: .red, disabled: !botManager.isRunning) { botManager.stopBot() }
                    QuickActionCard(title: locale.t(.dashReloadConfig), subtitle: locale.t(.dashReloadConfigSub), icon: "arrow.triangle.2.circlepath.circle.fill", color: .blue) {
                        botManager.loadConfig(); botManager.loadState()
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label(locale.t(.dashRecentActivity), systemImage: "text.justify.left")
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Text("\(botManager.logs.count) \(locale.t(.dashEntries))")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                    }

                    if botManager.logs.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "text.page.slash").font(.system(size: 28))
                                    .foregroundStyle(.secondary.opacity(0.5))
                                Text(locale.t(.dashNoActivity)).font(.system(size: 13)).foregroundStyle(.secondary)
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
                .background(RoundedRectangle(cornerRadius: 12).fill(.background)
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2))

                Spacer(minLength: 20)
            }
            .padding(32)
        }
        .id(tick)
        .onReceive(timer) { _ in if botManager.isRunning { tick.toggle() } }
    }
}

struct StatusCard: View {
    @EnvironmentObject var botManager: BotManager
    @EnvironmentObject var locale: LocaleManager

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(botManager.isRunning
                        ? LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [.secondary.opacity(0.3), .secondary.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 64, height: 64)
                    .shadow(color: botManager.isRunning ? .green.opacity(0.4) : .clear, radius: 16)
                Image(systemName: botManager.isRunning ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 26, weight: .medium)).foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(botManager.isRunning ? locale.t(.dashBotRunning) : locale.t(.dashBotStopped))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                if botManager.isRunning {
                    HStack(spacing: 16) {
                        Label(botManager.uptime, systemImage: "clock")
                        if !botManager.config.opencodeModel.isEmpty {
                            Label(botManager.config.opencodeModel, systemImage: "cpu")
                        }
                    }
                    .font(.system(size: 13)).foregroundStyle(.secondary)
                } else {
                    Text(locale.t(.dashBotStoppedDesc)).font(.system(size: 13)).foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                if botManager.isRunning { botManager.stopBot() } else { botManager.startBot() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: botManager.isRunning ? "stop.fill" : "play.fill")
                    Text(botManager.isRunning ? locale.t(.btnStop) : locale.t(.btnStart)).fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 10).fill(LinearGradient(
                    colors: botManager.isRunning ? [.red, .red.opacity(0.8)] : [.green, .green.opacity(0.8)],
                    startPoint: .top, endPoint: .bottom))
                    .shadow(color: botManager.isRunning ? .red.opacity(0.3) : .green.opacity(0.3), radius: 8, y: 2))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 16).fill(.background)
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4))
    }
}

struct StatCard: View {
    let title: String; let value: String; let icon: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon).font(.system(size: 20)).foregroundStyle(color)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.system(size: 24, weight: .bold, design: .rounded))
                Text(title).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(.background)
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2))
    }
}

struct QuickActionCard: View {
    let title: String; let subtitle: String; let icon: String; let color: Color
    var disabled: Bool = false
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 32))
                    .foregroundStyle(disabled ? .secondary.opacity(0.4) : color)
                VStack(spacing: 2) {
                    Text(title).font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(disabled ? .secondary : .primary)
                    Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity).padding(.vertical, 20)
            .background(RoundedRectangle(cornerRadius: 12).fill(.background)
                .shadow(color: .black.opacity(isHovered && !disabled ? 0.1 : 0.05), radius: isHovered && !disabled ? 12 : 8, y: 2))
            .scaleEffect(isHovered && !disabled ? 1.02 : 1.0)
        }
        .buttonStyle(.plain).disabled(disabled)
        .onHover { h in withAnimation(.easeOut(duration: 0.2)) { isHovered = h } }
    }
}

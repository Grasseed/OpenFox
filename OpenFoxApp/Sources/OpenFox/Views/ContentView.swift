import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard, configuration, logs, usage
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.33percent"
        case .configuration: return "gearshape.fill"
        case .logs: return "text.justify.left"
        case .usage: return "chart.bar.fill"
        }
    }

    @MainActor func label(_ locale: LocaleManager) -> String {
        switch self {
        case .dashboard: return locale.t(.navDashboard)
        case .configuration: return locale.t(.navConfiguration)
        case .logs: return locale.t(.navLogs)
        case .usage: return locale.t(.navUsage)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var botManager: BotManager
    @EnvironmentObject var locale: LocaleManager
    @State private var selectedItem: SidebarItem = .dashboard

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedItem)
        } detail: {
            ZStack {
                Color(nsColor: .windowBackgroundColor).ignoresSafeArea()
                switch selectedItem {
                case .dashboard: DashboardView()
                case .configuration: ConfigurationView()
                case .logs: LogsView()
                case .usage: UsageView()
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarItem
    @EnvironmentObject var botManager: BotManager
    @EnvironmentObject var locale: LocaleManager

    var body: some View {
        VStack(spacing: 0) {
            // Logo
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.orange, Color(red: 1.0, green: 0.45, blue: 0.0)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 56, height: 56)
                        .shadow(color: .orange.opacity(0.4), radius: 12, y: 4)
                    Text("🦊").font(.system(size: 28))
                }
                Text("OpenFox")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                HStack(spacing: 6) {
                    Circle()
                        .fill(botManager.isRunning ? Color.green : Color.secondary.opacity(0.4))
                        .frame(width: 8, height: 8)
                        .shadow(color: botManager.isRunning ? .green.opacity(0.6) : .clear, radius: 4)
                    Text(botManager.isRunning ? locale.t(.statusRunning) : locale.t(.statusStopped))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 20).padding(.bottom, 24)

            Divider().padding(.horizontal, 16)

            VStack(spacing: 4) {
                ForEach(SidebarItem.allCases) { item in
                    SidebarButton(item: item, isSelected: selection == item) {
                        withAnimation(.easeInOut(duration: 0.2)) { selection = item }
                    }
                }
            }
            .padding(.horizontal, 12).padding(.top, 16)

            Spacer()

            // Language picker
            HStack {
                Image(systemName: "globe")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Picker("", selection: $locale.language) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .controlSize(.small)
            }
            .padding(.horizontal, 16)

            // Controls
            VStack(spacing: 8) {
                Divider().padding(.horizontal, 16)
                HStack(spacing: 12) {
                    Button {
                        if botManager.isRunning { botManager.stopBot() } else { botManager.startBot() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: botManager.isRunning ? "stop.fill" : "play.fill")
                                .font(.system(size: 10))
                            Text(botManager.isRunning ? locale.t(.btnStop) : locale.t(.btnStart))
                                .font(.system(size: 12, weight: .medium))
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8)
                            .fill(botManager.isRunning ? Color.red.opacity(0.15) : Color.green.opacity(0.15)))
                        .foregroundStyle(botManager.isRunning ? .red : .green)
                    }
                    .buttonStyle(.plain)

                    Button { botManager.restartBot() } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .frame(width: 34, height: 34)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.1)))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain).disabled(!botManager.isRunning)
                }
                .padding(.horizontal, 12).padding(.bottom, 12)
            }
        }
        .frame(minWidth: 200, idealWidth: 220, maxWidth: 250)
    }
}

struct SidebarButton: View {
    @EnvironmentObject var locale: LocaleManager
    let item: SidebarItem
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .font(.system(size: 14, weight: .medium)).frame(width: 24)
                    .foregroundStyle(isSelected ? .orange : .secondary)
                Text(item.label(locale))
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(
                isSelected ? Color.orange.opacity(0.12) : (isHovered ? Color.secondary.opacity(0.08) : Color.clear)))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

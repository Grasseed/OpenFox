import SwiftUI

struct LogsView: View {
    @EnvironmentObject var botManager: BotManager
    @EnvironmentObject var locale: LocaleManager
    @State private var searchText = ""
    @State private var filterLevel: BotManager.LogLevel?
    @State private var autoScroll = true

    var filteredLogs: [BotManager.LogEntry] {
        botManager.logs.filter {
            (searchText.isEmpty || $0.message.localizedCaseInsensitiveContains(searchText))
            && (filterLevel == nil || $0.level == filterLevel)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(locale.t(.logsTitle)).font(.system(size: 28, weight: .bold, design: .rounded))
                        Text(locale.t(.logsSubtitle)).font(.system(size: 14)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Text("\(botManager.logs.count)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary).padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Capsule().fill(.secondary.opacity(0.1)))
                        Button { botManager.clearLogs() } label: { Label(locale.t(.btnClear), systemImage: "trash") }
                            .buttonStyle(.bordered).controlSize(.small)
                    }
                }

                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        TextField(locale.t(.logsFilter), text: $searchText).textFieldStyle(.plain).font(.system(size: 13))
                    }
                    .padding(8).background(RoundedRectangle(cornerRadius: 8).fill(.secondary.opacity(0.08)))

                    HStack(spacing: 4) {
                        FilterButton(label: locale.t(.logsAll), isSelected: filterLevel == nil) { filterLevel = nil }
                        FilterButton(label: "Info", isSelected: filterLevel == .info, color: .blue) { filterLevel = .info }
                        FilterButton(label: "Warn", isSelected: filterLevel == .warning, color: .yellow) { filterLevel = .warning }
                        FilterButton(label: "Error", isSelected: filterLevel == .error, color: .red) { filterLevel = .error }
                    }

                    Toggle(isOn: $autoScroll) {
                        Label(locale.t(.logsAutoScroll), systemImage: "arrow.down.to.line").font(.system(size: 12))
                    }
                    .toggleStyle(.switch).controlSize(.mini)
                }
            }
            .padding(24).padding(.bottom, 0)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredLogs) { entry in
                            LogRow(entry: entry, compact: false).id(entry.id)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                .onChange(of: botManager.logs.count) { _ in
                    if autoScroll, let last = filteredLogs.last {
                        withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
        }
    }
}

struct FilterButton: View {
    let label: String; let isSelected: Bool; var color: Color = .secondary; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .secondary)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(isSelected ? color.opacity(0.8) : .secondary.opacity(0.1)))
        }
        .buttonStyle(.plain)
    }
}

struct LogRow: View {
    let entry: BotManager.LogEntry; let compact: Bool

    private var levelColor: Color {
        switch entry.level {
        case .info: return .blue
        case .warning: return .yellow
        case .error: return .red
        case .debug: return .secondary
        }
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss.SSS"; return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(levelColor).frame(width: 6, height: 6).padding(.top, 6)
            if !compact {
                Text(Self.timeFormatter.string(from: entry.timestamp))
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary).frame(width: 85, alignment: .leading)
                Text(entry.level.rawValue)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(levelColor).frame(width: 40, alignment: .leading)
            }
            Text(entry.message)
                .font(.system(size: compact ? 12 : 12.5, design: .monospaced))
                .foregroundStyle(.primary.opacity(0.85)).lineLimit(compact ? 1 : nil)
                .frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled)
        }
        .padding(.vertical, compact ? 4 : 6).padding(.horizontal, compact ? 8 : 0)
    }
}

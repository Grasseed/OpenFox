import SwiftUI

struct UsageView: View {
    @EnvironmentObject var botManager: BotManager

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Usage Statistics")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Token consumption and session overview")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()

                    Button {
                        botManager.loadState()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.bottom, 8)

                // Token overview
                HStack(spacing: 16) {
                    UsageStatCard(
                        title: "Total Tokens",
                        value: botManager.usageStats.formattedTotal,
                        rawValue: botManager.usageStats.totalTokens,
                        icon: "number.circle.fill",
                        gradient: [.blue, .cyan]
                    )

                    UsageStatCard(
                        title: "Active Sessions",
                        value: "\(botManager.usageStats.activeSessions)",
                        rawValue: botManager.usageStats.activeSessions,
                        icon: "person.2.circle.fill",
                        gradient: [.orange, .yellow]
                    )
                }

                // Token breakdown
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.pie.fill")
                            .foregroundStyle(.purple)
                        Text("Token Breakdown")
                            .font(.system(size: 15, weight: .semibold))
                    }

                    if botManager.usageStats.totalTokens > 0 {
                        TokenBarChart(stats: botManager.usageStats)
                    }

                    VStack(spacing: 12) {
                        TokenRow(
                            label: "Input Tokens",
                            value: botManager.usageStats.formattedInput,
                            rawValue: botManager.usageStats.inputTokens,
                            total: botManager.usageStats.totalTokens,
                            color: .green,
                            icon: "arrow.down.circle.fill"
                        )
                        TokenRow(
                            label: "Output Tokens",
                            value: botManager.usageStats.formattedOutput,
                            rawValue: botManager.usageStats.outputTokens,
                            total: botManager.usageStats.totalTokens,
                            color: .purple,
                            icon: "arrow.up.circle.fill"
                        )
                        TokenRow(
                            label: "Reasoning Tokens",
                            value: botManager.usageStats.formattedReasoning,
                            rawValue: botManager.usageStats.reasoningTokens,
                            total: botManager.usageStats.totalTokens,
                            color: .orange,
                            icon: "brain"
                        )
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.background)
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                )

                // Configuration summary
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Current Configuration")
                            .font(.system(size: 15, weight: .semibold))
                    }

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        InfoTile(label: "Model", value: botManager.config.opencodeModel.isEmpty ? "Default" : botManager.config.opencodeModel)
                        InfoTile(label: "Variant", value: botManager.config.opencodeVariant.capitalized)
                        InfoTile(label: "Permission", value: botManager.config.opencodePermissionMode.capitalized)
                        InfoTile(label: "Groups", value: botManager.config.allowGroups ? "Allowed" : "Private Only")
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.background)
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                )

                Spacer(minLength: 20)
            }
            .padding(32)
        }
    }
}

struct UsageStatCard: View {
    let title: String
    let value: String
    let rawValue: Int
    let icon: String
    let gradient: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                if rawValue > 0 {
                    Text("\(rawValue.formatted()) exact")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }
}

struct TokenBarChart: View {
    let stats: UsageStats

    var body: some View {
        GeometryReader { geo in
            let total = max(stats.totalTokens, 1)
            let inputW = CGFloat(stats.inputTokens) / CGFloat(total) * geo.size.width
            let outputW = CGFloat(stats.outputTokens) / CGFloat(total) * geo.size.width
            let reasonW = CGFloat(stats.reasoningTokens) / CGFloat(total) * geo.size.width

            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.green)
                    .frame(width: max(inputW, 2))
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.purple)
                    .frame(width: max(outputW, 2))
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.orange)
                    .frame(width: max(reasonW, 2))
                Spacer(minLength: 0)
            }
        }
        .frame(height: 12)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct TokenRow: View {
    let label: String
    let value: String
    let rawValue: Int
    let total: Int
    let color: Color
    let icon: String

    private var percentage: String {
        guard total > 0 else { return "0%" }
        let pct = Double(rawValue) / Double(total) * 100
        return String(format: "%.1f%%", pct)
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(color)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 13, weight: .medium))

            Spacer()

            Text(percentage)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}

struct InfoTile: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.secondary.opacity(0.06))
        )
    }
}

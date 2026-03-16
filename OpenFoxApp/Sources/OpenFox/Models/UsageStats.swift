import Foundation

struct UsageStats {
    var totalTokens: Int = 0
    var inputTokens: Int = 0
    var outputTokens: Int = 0
    var reasoningTokens: Int = 0
    var activeSessions: Int = 0

    var formattedTotal: String { formatNumber(totalTokens) }
    var formattedInput: String { formatNumber(inputTokens) }
    var formattedOutput: String { formatNumber(outputTokens) }
    var formattedReasoning: String { formatNumber(reasoningTokens) }

    private func formatNumber(_ n: Int) -> String {
        if n >= 1_000_000 {
            return String(format: "%.1fM", Double(n) / 1_000_000)
        } else if n >= 1_000 {
            return String(format: "%.1fK", Double(n) / 1_000)
        }
        return "\(n)"
    }
}

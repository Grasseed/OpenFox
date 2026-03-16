import Foundation

struct ModelEntry: Identifiable, Hashable {
    let provider: String
    let model: String
    var id: String { "\(provider)/\(model)" }
    var fullName: String { "\(provider)/\(model)" }
}

@MainActor
final class ModelService: ObservableObject {
    static let shared = ModelService()

    @Published var providers: [String] = []
    @Published var modelsByProvider: [String: [ModelEntry]] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {}

    func loadModels(projectPath: String) async {
        isLoading = true
        errorMessage = nil

        let result = await Task.detached(priority: .utility) { () -> String in
            let proc = Process()
            let pipe = Pipe()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            proc.arguments = ["opencode", "models"]
            proc.standardOutput = pipe
            proc.standardError = Pipe()

            var env = ProcessInfo.processInfo.environment
            let paths = ["/usr/local/bin", "/opt/homebrew/bin", env["PATH"] ?? ""]
            env["PATH"] = paths.joined(separator: ":")
            proc.environment = env

            do {
                try proc.run()
                proc.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                return String(data: data, encoding: .utf8) ?? ""
            } catch {
                return ""
            }
        }.value

        parse(output: result)
        isLoading = false
    }

    private func parse(output: String) {
        var byProvider: [String: [ModelEntry]] = [:]
        let lines = output
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0.contains("/") }

        for line in lines {
            let parts = line.split(separator: "/", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let provider = String(parts[0])
            let model = String(parts[1])
            let entry = ModelEntry(provider: provider, model: model)
            byProvider[provider, default: []].append(entry)
        }

        modelsByProvider = byProvider
        providers = byProvider.keys.sorted()
    }

    func models(for provider: String) -> [ModelEntry] {
        modelsByProvider[provider] ?? []
    }
}

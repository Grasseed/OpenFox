import Foundation
import Combine

@MainActor
final class BotManager: ObservableObject {
    static let shared = BotManager()

    @Published var isRunning = false
    @Published var statusText = "Stopped"
    @Published var logs: [LogEntry] = []
    @Published var config: BotConfig = BotConfig()
    @Published var usageStats: UsageStats = UsageStats()
    @Published var startedAt: Date?
    @Published var botName: String = "OpenFox Bot"

    private var process: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    private var projectPath: String = ""

    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let level: LogLevel
    }

    enum LogLevel: String {
        case info = "INFO"
        case warning = "WARN"
        case error = "ERROR"
        case debug = "DEBUG"
    }

    private init() {
        detectProjectPath()
        loadConfig()
        loadState()
    }

    private func detectProjectPath() {
        // 1. Restore saved path first
        if let saved = UserDefaults.standard.string(forKey: "project_path"),
           FileManager.default.fileExists(atPath: saved + "/telegram-bot.mjs") {
            projectPath = saved
            return
        }

        let home = NSHomeDirectory()
        let candidates = [
            // Path relative to app bundle (when running from OpenFoxApp/build/)
            Bundle.main.bundlePath
                .components(separatedBy: "/OpenFoxApp")[0],
            // Common install locations
            home + "/tools/OpenFox",
            home + "/OpenFox",
            home + "/Projects/OpenFox",
            home + "/dev/OpenFox",
            "/usr/local/share/openfox",
            FileManager.default.currentDirectoryPath,
        ]
        for path in candidates {
            if FileManager.default.fileExists(atPath: path + "/telegram-bot.mjs") {
                projectPath = path
                UserDefaults.standard.set(path, forKey: "project_path")
                return
            }
        }
        // Fallback
        projectPath = home + "/tools/OpenFox"
    }

    func loadConfig() {
        let envPath = projectPath + "/.env"
        guard FileManager.default.fileExists(atPath: envPath),
              let content = try? String(contentsOfFile: envPath, encoding: .utf8) else {
            addLog("No .env file found at \(envPath)", level: .warning)
            return
        }
        config = BotConfig.parse(from: content)
        addLog("Configuration loaded", level: .info)
    }

    func saveConfig() {
        let envPath = projectPath + "/.env"
        let content = config.toEnvString()
        do {
            try content.write(toFile: envPath, atomically: true, encoding: .utf8)
            addLog("Configuration saved", level: .info)
        } catch {
            addLog("Failed to save config: \(error.localizedDescription)", level: .error)
        }
    }

    func loadState() {
        let statePath = projectPath + "/data/state.json"
        guard FileManager.default.fileExists(atPath: statePath),
              let data = try? Data(contentsOf: URL(fileURLWithPath: statePath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        if let usage = json["usage"] as? [String: Any] {
            usageStats.totalTokens = usage["total"] as? Int ?? 0
            usageStats.inputTokens = usage["input"] as? Int ?? 0
            usageStats.outputTokens = usage["output"] as? Int ?? 0
            usageStats.reasoningTokens = usage["reasoning"] as? Int ?? 0
        }
        if let chats = json["chats"] as? [String: Any] {
            usageStats.activeSessions = chats.count
        }
    }

    func startBot() {
        guard !isRunning else { return }

        let proc = Process()
        let outPipe = Pipe()
        let errPipe = Pipe()

        let scriptPath = projectPath + "/telegram-bot.mjs"
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            addLog("telegram-bot.mjs not found at: \(projectPath)", level: .error)
            addLog("Please set the correct OpenFox project path in Configuration.", level: .warning)
            return
        }

        proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        // Use absolute path to script so it works regardless of CWD
        proc.arguments = ["node", scriptPath]
        proc.currentDirectoryURL = URL(fileURLWithPath: projectPath)
        proc.standardOutput = outPipe
        proc.standardError = errPipe

        // Build PATH that includes all common node/opencode locations
        var env = ProcessInfo.processInfo.environment
        env["NODE_NO_WARNINGS"] = "1"
        let home = NSHomeDirectory()
        let extraPaths = [
            home + "/.opencode/bin",    // opencode default install
            home + "/.local/bin",
            "/opt/homebrew/bin",
            "/opt/homebrew/sbin",
            "/usr/local/bin",
            "/usr/bin",
            env["PATH"] ?? ""
        ]
        env["PATH"] = extraPaths.joined(separator: ":")
        proc.environment = env

        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let str = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor [weak self] in
                for line in str.components(separatedBy: .newlines) where !line.isEmpty {
                    self?.addLog(line, level: .info)
                }
            }
        }

        errPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let str = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor [weak self] in
                for line in str.components(separatedBy: .newlines) where !line.isEmpty {
                    self?.addLog(line, level: .error)
                }
            }
        }

        proc.terminationHandler = { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.isRunning = false
                self?.statusText = "Stopped"
                self?.startedAt = nil
                self?.addLog("Bot process terminated", level: .warning)
            }
        }

        do {
            try proc.run()
            process = proc
            outputPipe = outPipe
            errorPipe = errPipe
            isRunning = true
            statusText = "Running"
            startedAt = Date()
            addLog("Bot started (PID: \(proc.processIdentifier))", level: .info)
        } catch {
            addLog("Failed to start: \(error.localizedDescription)", level: .error)
        }
    }

    func stopBot() {
        guard let proc = process, proc.isRunning else { return }
        proc.interrupt()
        addLog("Stopping bot...", level: .info)

        DispatchQueue.global().asyncAfter(deadline: .now() + 3) { [weak self] in
            if proc.isRunning {
                proc.terminate()
                Task { @MainActor [weak self] in
                    self?.addLog("Bot force terminated", level: .warning)
                }
            }
        }

        isRunning = false
        statusText = "Stopped"
        startedAt = nil
    }

    func restartBot() {
        stopBot()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.startBot()
        }
    }

    func clearLogs() {
        logs.removeAll()
    }

    func addLog(_ message: String, level: LogLevel) {
        let entry = LogEntry(timestamp: Date(), message: message, level: level)
        logs.append(entry)
        if logs.count > 5000 {
            logs.removeFirst(logs.count - 5000)
        }
    }

    var uptime: String {
        guard let start = startedAt else { return "--" }
        let interval = Date().timeIntervalSince(start)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        }
        return String(format: "%ds", seconds)
    }

    var projectDirectory: String { projectPath }

    func setProjectPath(_ path: String) {
        projectPath = path
        if FileManager.default.fileExists(atPath: path + "/telegram-bot.mjs") {
            // Only persist valid paths
            UserDefaults.standard.set(path, forKey: "project_path")
            addLog("Project path set: \(path)", level: .info)
        } else {
            addLog("Warning: telegram-bot.mjs not found in \(path)", level: .warning)
            addLog("Bot cannot start from this directory.", level: .warning)
        }
        loadConfig()
        loadState()
    }

    func autoDetectProjectPath() {
        // Clear saved path and re-run detection
        UserDefaults.standard.removeObject(forKey: "project_path")
        detectProjectPath()
        loadConfig()
        loadState()
        addLog("Auto-detected project path: \(projectPath)", level: .info)
    }
}

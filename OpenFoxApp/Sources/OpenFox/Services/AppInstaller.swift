import Foundation

/// Manages the first-run installation of bundled OpenFox project files
/// into ~/Library/Application Support/OpenFox/
final class AppInstaller {
    static let shared = AppInstaller()

    /// The canonical user-data directory for OpenFox
    static var appSupportDir: String {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!.path
        return support + "/OpenFox"
    }

    private init() {}

    /// Returns true if the installed project looks complete
    var isInstalled: Bool {
        FileManager.default.fileExists(
            atPath: Self.appSupportDir + "/telegram-bot.mjs"
        )
    }

    /// Copy bundled JS files to Application Support on first run.
    /// Safe to call on every launch — skips if already installed.
    /// Returns the install path.
    @discardableResult
    func installIfNeeded() -> String {
        let dest = Self.appSupportDir
        guard !isInstalled else { return dest }

        do {
            try copyBundledProject(to: dest)
        } catch {
            // Non-fatal: will surface as "file not found" in BotManager
            print("[AppInstaller] Failed to install: \(error)")
        }
        return dest
    }

    /// Force re-copy from bundle (used by "Reinstall" action)
    func reinstall() throws {
        let dest = Self.appSupportDir
        // Remove only JS files, keep user's .env and data/
        let managed = [
            "telegram-bot.mjs", "telegram-webhook-handler.mjs",
            "config.mjs", "package.json", "lib"
        ]
        for name in managed {
            let path = dest + "/" + name
            try? FileManager.default.removeItem(atPath: path)
        }
        try copyBundledProject(to: dest)
    }

    // MARK: - Private

    private func copyBundledProject(to dest: String) throws {
        let fm = FileManager.default

        // Find bundled project directory
        guard let bundleURL = Bundle.module.resourceURL?
            .appendingPathComponent("project") else {
            throw InstallError.bundleNotFound
        }

        // Create destination
        try fm.createDirectory(atPath: dest, withIntermediateDirectories: true)
        try fm.createDirectory(atPath: dest + "/data", withIntermediateDirectories: true)

        // Copy all files from bundle
        let items = try fm.contentsOfDirectory(at: bundleURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles)

        for item in items {
            let destPath = dest + "/" + item.lastPathComponent
            if fm.fileExists(atPath: destPath) {
                try fm.removeItem(atPath: destPath)
            }
            try fm.copyItem(at: item, to: URL(fileURLWithPath: destPath))
        }

        // Copy lib/ subdirectory
        let libSrc = bundleURL.appendingPathComponent("lib")
        let libDest = URL(fileURLWithPath: dest + "/lib")
        if fm.fileExists(atPath: libDest.path) {
            try fm.removeItem(at: libDest)
        }
        if fm.fileExists(atPath: libSrc.path) {
            try fm.copyItem(at: libSrc, to: libDest)
        }

        // Create .env from example if no .env exists yet
        let envDest = dest + "/.env"
        if !fm.fileExists(atPath: envDest) {
            // Try to copy .env.example
            let exampleSrc = bundleURL.appendingPathComponent(".env.example")
            if fm.fileExists(atPath: exampleSrc.path) {
                try fm.copyItem(at: exampleSrc, to: URL(fileURLWithPath: envDest))
            } else {
                // Create a blank .env
                try "# OpenFox configuration\nBOT_TOKEN=\n".write(
                    toFile: envDest, atomically: true, encoding: .utf8)
            }
        }

        // Create empty state.json if missing
        let stateFile = dest + "/data/state.json"
        if !fm.fileExists(atPath: stateFile) {
            let emptyState = """
            {"offset":null,"chats":{},"settings":{"model":null},"usage":{"total":0,"input":0,"output":0,"reasoning":0}}
            """
            try emptyState.write(toFile: stateFile, atomically: true, encoding: .utf8)
        }

        print("[AppInstaller] Installed to \(dest)")
    }

    enum InstallError: Error {
        case bundleNotFound
    }
}

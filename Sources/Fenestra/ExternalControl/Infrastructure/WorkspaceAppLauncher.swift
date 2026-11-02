import AppKit
import os

private let log = Logger(subsystem: "com.florentamaridon.Fenestra", category: "commands")

/// `AppLauncher` backed by `NSWorkspace`: finds an app by bundle identifier, then by name in the
/// usual application folders.
@MainActor
final class WorkspaceAppLauncher: AppLauncher {
    func launch(_ apps: [String]) async {
        for app in apps {
            guard let url = Self.applicationURL(for: app) else {
                log.info("no application found for \(app, privacy: .public)")
                continue
            }
            let configuration = NSWorkspace.OpenConfiguration()
            // Activation makes a running app without windows open one (reopen event).
            configuration.activates = true
            do {
                _ = try await NSWorkspace.shared.openApplication(at: url, configuration: configuration)
            } catch {
                log.info("could not open \(app, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private static func applicationURL(for app: String) -> URL? {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app) { return url }
        let name = app.hasSuffix(".app") ? app : app + ".app"
        let folders = ["/Applications", "/Applications/Utilities", "/System/Applications",
                       "/System/Applications/Utilities", NSHomeDirectory() + "/Applications"]
        return folders.lazy
            .map { URL(fileURLWithPath: $0).appendingPathComponent(name) }
            .first { FileManager.default.fileExists(atPath: $0.path) }
    }
}

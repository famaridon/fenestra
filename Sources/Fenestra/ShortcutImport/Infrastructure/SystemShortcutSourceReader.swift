import Foundation

/// `ShortcutSourceReader` on the real Mac: another app's preferences domain (through `UserDefaults`, or its
/// sandbox container for an App Store app such as Magnet) or its configuration file in the home folder.
@MainActor
final class SystemShortcutSourceReader: ShortcutSourceReader {
    private let home = FileManager.default.homeDirectoryForCurrentUser

    func read(_ source: ShortcutSource) -> ShortcutSourceData? {
        if let domain = source.preferencesDomain {
            return preferences(of: domain).map { .preferences($0) }
        }
        for path in source.configurationPaths {
            if let text = try? String(contentsOf: url(for: path), encoding: .utf8) { return .text(text) }
        }
        return nil
    }

    private func preferences(of domain: String) -> [String: Any]? {
        if let values = UserDefaults.standard.persistentDomain(forName: domain), !values.isEmpty { return values }
        let container = home.appending(path: "Library/Containers/\(domain)/Data/Library/Preferences/\(domain).plist")
        guard let data = try? Data(contentsOf: container),
              let values = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              !values.isEmpty else { return nil }
        return values
    }

    /// `.config/…` follows `$XDG_CONFIG_HOME` when it is set, as the apps themselves do.
    private func url(for path: String) -> URL {
        if path.hasPrefix(".config/"), let xdg = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"], !xdg.isEmpty {
            return URL(fileURLWithPath: xdg).appending(path: String(path.dropFirst(".config/".count)))
        }
        return home.appending(path: path)
    }
}

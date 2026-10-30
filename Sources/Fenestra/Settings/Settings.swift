import Foundation
import Observation

/// User settings, persisted to UserDefaults in each property's `didSet` and read back in `init`.
@MainActor
@Observable
final class Settings {
    static let shared = Settings()

    var isEnabled: Bool { didSet { store(isEnabled, "isEnabled") } }
    var dragSnapEnabled: Bool { didSet { store(dragSnapEnabled, "dragSnapEnabled") } }
    var restoreOnUnsnap: Bool { didSet { store(restoreOnUnsnap, "restoreOnUnsnap") } }
    var gap: Double { didSet { store(gap, "gap") } }
    var cornerLength: Double { didSet { store(cornerLength, "cornerLength") } }
    var innerEdgeThreshold: Double { didSet { store(innerEdgeThreshold, "innerEdgeThreshold") } }
    var enabledZones: Set<Zone> { didSet { storeJSON(enabledZones, "enabledZones") } }
    var portraitTopEdgeMaximizes: Bool { didSet { store(portraitTopEdgeMaximizes, "portraitTopEdgeMaximizes") } }
    var portraitSideEdgesEnabled: Bool { didSet { store(portraitSideEdgesEnabled, "portraitSideEdgesEnabled") } }
    var portraitArrowsSplitHalves: Bool { didSet { store(portraitArrowsSplitHalves, "portraitArrowsSplitHalves") } }
    var sharedBorderEnabled: Bool { didSet { store(sharedBorderEnabled, "sharedBorderEnabled") } }
    var snapAssistEnabled: Bool { didSet { store(snapAssistEnabled, "snapAssistEnabled") } }
    /// Window thumbnails in Snap Assist; needs the Screen Recording permission.
    var snapAssistPreviews: Bool { didSet { store(snapAssistPreviews, "snapAssistPreviews") } }
    /// Palette of layouts when the pointer rests on a window's zoom button.
    var snapLayoutsEnabled: Bool { didSet { store(snapLayoutsEnabled, "snapLayoutsEnabled") } }
    var excludedBundleIdentifiers: [String] { didSet { storeJSON(excludedBundleIdentifiers, "excludedBundleIdentifiers") } }
    var shortcuts: [SnapAction: KeyboardShortcut] {
        didSet {
            storeJSON(Dictionary(uniqueKeysWithValues: shortcuts.map { ($0.key.rawValue, $0.value) }), "shortcuts")
        }
    }
    var hasCompletedOnboarding: Bool { didSet { store(hasCompletedOnboarding, "hasCompletedOnboarding") } }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isEnabled = defaults.object(forKey: "isEnabled") as? Bool ?? true
        dragSnapEnabled = defaults.object(forKey: "dragSnapEnabled") as? Bool ?? true
        restoreOnUnsnap = defaults.object(forKey: "restoreOnUnsnap") as? Bool ?? true
        gap = defaults.object(forKey: "gap") as? Double ?? 0
        cornerLength = defaults.object(forKey: "cornerLength") as? Double ?? 120
        innerEdgeThreshold = defaults.object(forKey: "innerEdgeThreshold") as? Double ?? 24
        enabledZones = Self.loadJSON(Set<Zone>.self, "enabledZones", defaults) ?? Zone.defaultEnabled
        portraitTopEdgeMaximizes = defaults.object(forKey: "portraitTopEdgeMaximizes") as? Bool ?? false
        portraitSideEdgesEnabled = defaults.object(forKey: "portraitSideEdgesEnabled") as? Bool ?? true
        portraitArrowsSplitHalves = defaults.object(forKey: "portraitArrowsSplitHalves") as? Bool ?? true
        sharedBorderEnabled = defaults.object(forKey: "sharedBorderEnabled") as? Bool ?? true
        snapAssistEnabled = defaults.object(forKey: "snapAssistEnabled") as? Bool ?? true
        snapAssistPreviews = defaults.object(forKey: "snapAssistPreviews") as? Bool ?? false
        snapLayoutsEnabled = defaults.object(forKey: "snapLayoutsEnabled") as? Bool ?? true
        excludedBundleIdentifiers = Self.loadJSON([String].self, "excludedBundleIdentifiers", defaults) ?? []
        if let raw = Self.loadJSON([String: KeyboardShortcut].self, "shortcuts", defaults) {
            shortcuts = Dictionary(uniqueKeysWithValues: raw.compactMap { key, value in
                SnapAction(rawValue: key).map { ($0, value) }
            })
        } else {
            shortcuts = SnapAction.defaultShortcuts
        }
        hasCompletedOnboarding = defaults.object(forKey: "hasCompletedOnboarding") as? Bool ?? false
    }

    func resetShortcuts() {
        shortcuts = SnapAction.defaultShortcuts
    }

    func isExcluded(bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier else { return false }
        return excludedBundleIdentifiers.contains(bundleIdentifier)
    }

    var keyboardResolver: KeyboardSnapResolver {
        KeyboardSnapResolver(portraitArrowsSplitHalves: portraitArrowsSplitHalves)
    }

    var dragResolverConfig: DragZoneResolver.Config {
        DragZoneResolver.Config(
            innerEdgeThreshold: CGFloat(innerEdgeThreshold),
            cornerLength: CGFloat(cornerLength),
            portraitTopEdgeMaximizes: portraitTopEdgeMaximizes,
            portraitSideEdgesEnabled: portraitSideEdgesEnabled,
            enabledZones: enabledZones
        )
    }

    private func store(_ value: Any, _ key: String) {
        defaults.set(value, forKey: key)
    }

    private func storeJSON<T: Encodable>(_ value: T, _ key: String) {
        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }

    private static func loadJSON<T: Decodable>(_ type: T.Type, _ key: String, _ defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

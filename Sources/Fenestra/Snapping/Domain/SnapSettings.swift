import CoreGraphics
import Foundation

/// Snapshot of the settings the snapping use cases read (taken at each event, so changes apply at once).
struct SnapSettings: Sendable, Equatable {
    var dragSnapEnabled = true
    var restoreOnUnsnap = true
    /// Gap between windows and with the screen edges, in points.
    var gap: CGFloat = 0
    var enabledZones: Set<Zone> = Zone.defaultEnabled
    var dragResolver = DragZoneResolver.Config()
    var portraitArrowsSplitHalves = true
    var sharedBorderEnabled = true
    var snapAssistEnabled = true
    var snapAssistPreviews = false
    var excludedBundleIdentifiers: Set<String> = []

    init() {}

    var keyboardResolver: KeyboardSnapResolver {
        KeyboardSnapResolver(portraitArrowsSplitHalves: portraitArrowsSplitHalves)
    }

    func isExcluded(bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier else { return false }
        return excludedBundleIdentifiers.contains(bundleIdentifier)
    }
}

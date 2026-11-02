/// Moves a window into a zone of a screen and remembers it as snapped (the restore frame of an
/// already snapped window is kept). No raise, no Snap Assist: the callers decide.
@MainActor
final class PlaceWindowInZone {
    private let store: SnapStore
    private let settings: any SnapSettingsProvider

    init(store: SnapStore, settings: any SnapSettingsProvider) {
        self.store = store
        self.settings = settings
    }

    func execute(_ window: any WindowHandle, zone: Zone, on screen: ScreenInfo) {
        guard let current = window.frame else {
            store.remove(window)
            return
        }
        let target = zone.frame(in: screen.visibleFrame, gap: settings.snapSettings.gap)
        let actual = window.setFrame(target) ?? target
        store.recordSnap(window, zone: zone, screenID: screen.id, snappedFrame: actual, currentFrame: current)
    }
}

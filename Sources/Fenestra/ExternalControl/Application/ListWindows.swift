/// `list_windows`: the manageable windows, front-most first within each app, with their display and zone.
@MainActor
final class ListWindows {
    private let displays: any DisplayProvider
    private let manageable: ManageableWindows
    private let store: SnapStore

    init(displays: any DisplayProvider, manageable: ManageableWindows, store: SnapStore) {
        self.displays = displays
        self.manageable = manageable
        self.store = store
    }

    func execute() -> [ControlResults.WindowInfo] {
        let layout = displays.currentLayout()
        return manageable.all().map { window in
            let frame = window.frame
            let screen = frame.flatMap { layout.screen(for: $0) }
            let snapped = frame.map { store.isStillSnapped(window, frame: $0) } ?? false
            return ControlResults.WindowInfo(
                app: window.appName, bundleIdentifier: window.bundleIdentifier, title: window.title,
                display: screen.flatMap { layout.displayIndex(of: $0) },
                zone: snapped ? store.record(for: window)?.zone : nil, frame: frame.map(ControlResults.Rect.init))
        }
    }
}

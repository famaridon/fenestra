/// Which windows Fenestra may move: standard, resizable, not full screen, app not excluded.
/// Fixed-size windows are left alone.
@MainActor
final class ManageableWindows {
    private let windows: any WindowSystem
    private let settings: any SnapSettingsProvider

    init(windows: any WindowSystem, settings: any SnapSettingsProvider) {
        self.windows = windows
        self.settings = settings
    }

    func isManageable(_ window: any WindowHandle) -> Bool {
        window.isStandardWindow && !window.isFullScreen && window.isResizable
            && !settings.snapSettings.isExcluded(bundleIdentifier: window.bundleIdentifier)
    }

    /// Visible manageable windows, front-most first within each app.
    func all() -> [any WindowHandle] {
        windows.visibleStandardWindows().filter(isManageable)
    }
}

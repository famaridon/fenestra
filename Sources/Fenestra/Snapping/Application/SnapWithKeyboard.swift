/// Applies a snap action (hotkey or menu) to the frontmost window.
@MainActor
final class SnapWithKeyboard {
    private let windows: any WindowSystem
    private let manageable: ManageableWindows
    private let displays: any DisplayProvider
    private let store: SnapStore
    private let snap: SnapWindowToZone
    private let followUp: any SnapFollowUp
    private let settings: any SnapSettingsProvider

    init(windows: any WindowSystem, manageable: ManageableWindows, displays: any DisplayProvider,
         store: SnapStore, snap: SnapWindowToZone, followUp: any SnapFollowUp, settings: any SnapSettingsProvider) {
        self.windows = windows
        self.manageable = manageable
        self.displays = displays
        self.store = store
        self.snap = snap
        self.followUp = followUp
        self.settings = settings
    }

    func execute(_ action: SnapAction) {
        // Hotkeys never reach the Snap Assist panel's Escape monitor: each new action replaces the previous offer.
        followUp.cancel()
        guard let window = windows.frontmostWindow(), manageable.isManageable(window),
              let frame = window.frame else { return }
        let layout = displays.currentLayout()
        guard let screen = layout.screen(for: frame) else { return }
        let state = store.currentRecord(for: window, frame: frame)
            .map { WindowSnapState(zone: $0.zone, screenID: $0.screenID) }
        let settings = settings.snapSettings
        switch settings.keyboardResolver.command(for: action, state: state, on: screen, layout: layout) {
        case .place(let zone, _) where !settings.enabledZones.contains(zone):
            // A disabled zone is never used, and there is no fallback to another one.
            return
        case .place(let zone, let target):
            snap.execute(window, zone: zone, on: target)
        case .restore:
            guard let record = store.remove(window) else { return }
            window.setFrame(record.restoreFrame)
        case .none:
            guard state == nil, action == .nextDisplay || action == .previousDisplay,
                  let target = action == .nextDisplay ? layout.next(after: screen) : layout.previous(before: screen)
            else { return }
            window.setFrame(SnapGeometry.proportionalFrame(frame, from: screen.visibleFrame, to: target.visibleFrame))
            window.raise()
        }
    }
}

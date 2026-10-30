import AppKit
import Observation

/// Assembly point of the app. Owns the settings, the permission tracker and the controllers.
@MainActor
@Observable
final class AppController {
    let settings: Settings
    let permission: AccessibilityPermission

    @ObservationIgnored let dragMonitor = DragMonitor()
    @ObservationIgnored let hotkeys = HotkeyManager()
    @ObservationIgnored let snapController: SnapController
    @ObservationIgnored let snapAssist: SnapAssistController
    @ObservationIgnored let snapLayouts: SnapLayoutsController
    @ObservationIgnored let screenWatcher: ScreenWatcher

    /// True while the global monitors (mouse + hotkeys) are active.
    private(set) var isRunning = false

    /// True when the welcome window should be shown.
    var wantsOnboarding: Bool { !settings.hasCompletedOnboarding || !permission.isGranted }

    init(settings: Settings = .shared, permission: AccessibilityPermission = AccessibilityPermission()) {
        self.settings = settings
        self.permission = permission
        let snap = SnapController(settings: settings)
        let assist = SnapAssistController(settings: settings, snapController: snap)
        snap.snapAssist = assist
        snapController = snap
        snapAssist = assist
        snapLayouts = SnapLayoutsController(settings: settings, snapController: snap)
        screenWatcher = ScreenWatcher(snapController: snap)
        hotkeys.onAction = { [weak self] action in self?.perform(action) }
        refresh()
        observeChanges()
    }

    /// Applies a snap action to the frontmost window (used by hotkeys and menus).
    func perform(_ action: SnapAction) {
        snapController.perform(action)
    }

    /// Starts or stops the monitors according to the permission and the master switch.
    func refresh() {
        let active = permission.isGranted && settings.isEnabled
        if active {
            if settings.dragSnapEnabled {
                dragMonitor.onMouseDown = { [snapController] in snapController.mouseDown(at: $0) }
                dragMonitor.onMouseDragged = { [snapController] in snapController.mouseDragged(at: $0) }
                dragMonitor.onMouseUp = { [snapController] in snapController.mouseUp(at: $0) }
            } else {
                dragMonitor.onMouseDown = nil
                dragMonitor.onMouseDragged = nil
                dragMonitor.onMouseUp = nil
                snapController.cancelDrag()
            }
            dragMonitor.start()
            hotkeys.register(settings.shortcuts)
            if settings.snapLayoutsEnabled { snapLayouts.start() } else { snapLayouts.stop() }
        } else {
            dragMonitor.stop()
            hotkeys.unregisterAll()
            snapLayouts.stop()
            snapController.cancelDrag()
        }
        isRunning = active
    }

    /// Re-runs `refresh()` whenever one of the inputs changes (re-armed after each change).
    private func observeChanges() {
        withObservationTracking {
            _ = permission.isGranted
            _ = settings.isEnabled
            _ = settings.shortcuts
            _ = settings.dragSnapEnabled
            _ = settings.snapLayoutsEnabled
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.refresh()
                self?.observeChanges()
            }
        }
    }
}

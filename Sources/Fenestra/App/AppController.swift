import AppKit
import Observation
import os

/// Composition root: builds the adapters and the use cases, wires them together, and starts or
/// stops the monitors according to the permission and the settings.
@MainActor
@Observable
final class AppController {
    private static let logger = Logger(subsystem: "com.florentamaridon.Fenestra", category: "app")
    let settings: Settings
    let permission: AccessibilityPermission
    @ObservationIgnored let loginItem: any LoginItem = LaunchAtLogin()
    @ObservationIgnored let screenRecording: any ScreenRecordingAccess = ScreenRecordingPermission()
    /// Shortcuts of Rectangle, Magnet or AeroSpace (welcome window and Shortcuts tab).
    @ObservationIgnored let detectShortcutSources: DetectShortcutSources
    @ObservationIgnored let importShortcuts: ImportShortcuts
    /// Saved window arrangements (menu, settings, `fenestra workspace`).
    let workspaces: WorkspaceCollection
    @ObservationIgnored let saveWorkspace: SaveWorkspace
    @ObservationIgnored let applyWorkspace: ApplyWorkspace
    /// Which settings tab the menu wants open.
    @ObservationIgnored let navigation = SettingsNavigation()
    /// The connected displays (the Workspaces tab remembers them for the automatic switch).
    @ObservationIgnored let displays: any DisplayProvider

    @ObservationIgnored private let dragMonitor = DragMonitor()
    @ObservationIgnored private let hotkeys = HotkeyManager()
    @ObservationIgnored private let dragSession: DragSnapSession
    @ObservationIgnored private let snapWithKeyboard: SnapWithKeyboard
    @ObservationIgnored private let snapLayoutsMonitor: ZoomButtonHoverMonitor
    @ObservationIgnored private let screenWatcher: ScreenWatcher
    @ObservationIgnored private let controlServer: ControlServer

    /// True while the global monitors (mouse + hotkeys) are active.
    private(set) var isRunning = false

    /// True when the welcome window should be shown.
    var wantsOnboarding: Bool { !settings.hasCompletedOnboarding || !permission.isGranted }

    init(settings: Settings = .shared, trust: any AccessibilityTrust = AXAccessibilityTrust()) {
        self.settings = settings
        permission = AccessibilityPermission(trust: trust)

        let shortcutSources = SystemShortcutSourceReader()
        detectShortcutSources = DetectShortcutSources(reader: shortcutSources)
        importShortcuts = ImportShortcuts(reader: shortcutSources, store: settings)

        // Adapters shared by every feature.
        let windows = AXWindowSystem()
        let displays = NSScreenDisplays()
        self.displays = displays
        let pointer = SystemPointer()

        // Snapping core.
        let store = SnapStore()
        let manageable = ManageableWindows(windows: windows, settings: settings)
        let place = PlaceWindowInZone(store: store, settings: settings)

        // Snap Assist and the shared border plug into snapping through its ports.
        let snapAssist = OfferSnapAssist(store: store, manageable: manageable, place: place,
                                         presenter: SnapAssistPanel(), thumbnails: WindowThumbnailer(),
                                         screenRecording: screenRecording, settings: settings)
        let sharedBorder = PropagateBorderResize(store: store, settings: settings)
        let snap = SnapWindowToZone(place: place, followUp: snapAssist)

        snapWithKeyboard = SnapWithKeyboard(windows: windows, manageable: manageable, displays: displays,
                                            store: store, snap: snap, followUp: snapAssist, settings: settings)
        dragSession = DragSnapSession(windows: windows, manageable: manageable, displays: displays,
                                      pointer: pointer, store: store, place: place, preview: SnapPreviewPanel(),
                                      followUp: snapAssist, resizeHandler: sharedBorder, settings: settings)
        snapLayoutsMonitor = ZoomButtonHoverMonitor(showSnapLayouts: ShowSnapLayouts(
            locator: AXZoomButtonLocator(), pointer: pointer, displays: displays, manageable: manageable,
            presenter: SnapLayoutsPanel(), snap: snap, settings: settings))
        // Workspaces: saved layouts, applied through the same use case as the tool's apply_layout.
        let applyLayout = ApplyLayout(manageable: manageable, displays: displays, store: store, place: place,
                                      launcher: WorkspaceAppLauncher(), settings: settings)
        let workspaces = WorkspaceCollection(store: FileWorkspaceStore())
        self.workspaces = workspaces
        saveWorkspace = SaveWorkspace(workspaces: workspaces, manageable: manageable, displays: displays,
                                      store: store, stacking: CGWindowStacking(), settings: settings)
        let applyWorkspace = ApplyWorkspace(workspaces: workspaces, displays: displays, applyLayout: applyLayout)
        self.applyWorkspace = applyWorkspace

        // Display changes: snapped windows back in their zones, then the workspace saved for these displays.
        let reapplySnaps = ReapplySnapsAfterDisplayChange(store: store, displays: displays, place: place)
        let workspaceForDisplays = ApplyWorkspaceForDisplays(workspaces: workspaces, displays: displays,
                                                             applyWorkspace: applyWorkspace)
        screenWatcher = ScreenWatcher {
            reapplySnaps.execute()
            await workspaceForDisplays.execute()
        }

        // External control (fenestra CLI, MCP).
        let dispatcher = CommandDispatcher(
            trust: trust, settings: settings,
            listDisplays: ListDisplays(displays: displays),
            listWindows: ListWindows(displays: displays, manageable: manageable, store: store),
            applyLayout: applyLayout,
            listWorkspaces: ListWorkspaces(workspaces: workspaces), saveWorkspace: saveWorkspace,
            applyWorkspace: applyWorkspace, deleteWorkspace: DeleteWorkspace(workspaces: workspaces))
        controlServer = ControlServer { request in await dispatcher.handle(request) }

        refresh()
        observeChanges()
    }

    /// Every global shortcut: the snap actions, then the workspaces. A workspace whose shortcut a snap action
    /// already uses is skipped and logged (the settings show both, the user picks).
    private func hotkeyBindings() -> [KeyboardShortcut: HotkeyManager.Action] {
        var bindings: [KeyboardShortcut: HotkeyManager.Action] = [:]
        for (action, shortcut) in settings.shortcuts {
            bindings[shortcut] = { [weak self] in self?.perform(action) }
        }
        for workspace in workspaces.all {
            guard let shortcut = workspace.shortcut else { continue }
            guard bindings[shortcut] == nil else {
                Self.logger.info("\(shortcut.displayString, privacy: .public) of workspace \(workspace.name, privacy: .public) is taken by a snap action")
                continue
            }
            bindings[shortcut] = { [weak self] in
                guard let self else { return }
                Task { await self.applyWorkspace.execute(workspace) }
            }
        }
        return bindings
    }

    /// Applies a snap action to the frontmost window (used by hotkeys and menus).
    func perform(_ action: SnapAction) {
        snapWithKeyboard.execute(action)
    }

    /// Starts or stops the monitors according to the permission and the master switch.
    func refresh() {
        let active = permission.isGranted && settings.isEnabled
        if active {
            // The mouse also drives unsnap restoration and the shared border, not only drag snapping.
            if settings.dragSnapEnabled || settings.restoreOnUnsnap || settings.sharedBorderEnabled {
                dragMonitor.onMouseDown = { [dragSession] in dragSession.mouseDown(at: $0) }
                dragMonitor.onMouseDragged = { [dragSession] in dragSession.mouseDragged(at: $0) }
                dragMonitor.onMouseUp = { [dragSession] in dragSession.mouseUp(at: $0) }
            } else {
                dragMonitor.onMouseDown = nil
                dragMonitor.onMouseDragged = nil
                dragMonitor.onMouseUp = nil
            }
            dragSession.cancel()
            dragMonitor.start()
            hotkeys.register(hotkeyBindings())
            if settings.snapLayoutsEnabled { snapLayoutsMonitor.start() } else { snapLayoutsMonitor.stop() }
        } else {
            dragMonitor.stop()
            hotkeys.unregisterAll()
            snapLayoutsMonitor.stop()
            dragSession.cancel()
        }
        isRunning = active
        // Independent of `active`: the tool then gets a clear error instead of no answer.
        if settings.externalControlEnabled { controlServer.start() } else { controlServer.stop() }
    }

    /// Re-runs `refresh()` whenever one of the inputs changes (re-armed after each change).
    private func observeChanges() {
        withObservationTracking {
            _ = permission.isGranted
            _ = settings.isEnabled
            _ = settings.shortcuts
            _ = workspaces.all
            _ = settings.dragSnapEnabled
            _ = settings.restoreOnUnsnap
            _ = settings.sharedBorderEnabled
            _ = settings.snapLayoutsEnabled
            _ = settings.externalControlEnabled
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.refresh()
                self?.observeChanges()
            }
        }
    }
}

import CoreGraphics
import Foundation
@testable import Fenestra

// Fakes of the ports, to test the use cases without Accessibility, AppKit or real displays.

@MainActor
final class FakeWindow: WindowHandle {
    nonisolated let id: Int
    nonisolated let pid: pid_t
    var frame: CGRect?
    var title: String?
    var appName: String?
    var bundleIdentifier: String?
    var isStandardWindow = true
    var isFullScreen = false
    var isResizable = true
    /// The app refuses to go below this size, as real apps do.
    var minSize: CGSize = .zero
    private(set) var raiseCount = 0

    init(id: Int, frame: CGRect?, appName: String? = nil, bundleIdentifier: String? = nil, title: String? = nil) {
        self.id = id
        self.pid = pid_t(1000 + id)
        self.frame = frame
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.title = title
    }

    @discardableResult
    func setFrame(_ target: CGRect) -> CGRect? {
        guard frame != nil else { return nil }
        let actual = CGRect(origin: target.origin, size: CGSize(width: max(target.width, minSize.width),
                                                                height: max(target.height, minSize.height)))
        frame = actual
        return actual
    }

    func raise() { raiseCount += 1 }

    nonisolated static func == (lhs: FakeWindow, rhs: FakeWindow) -> Bool { lhs.id == rhs.id }
    nonisolated func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

@MainActor
final class FakeWindowSystem: WindowSystem {
    var windows: [FakeWindow] = []
    var frontmost: FakeWindow?
    var underPointer: FakeWindow?

    func frontmostWindow() -> (any WindowHandle)? { frontmost }
    func window(at point: CGPoint) -> (any WindowHandle)? { underPointer }
    func visibleStandardWindows() -> [any WindowHandle] { windows.filter(\.isStandardWindow) }
}

@MainActor
final class FakeDisplays: DisplayProvider {
    var layout: ScreenLayout
    init(_ layout: ScreenLayout) { self.layout = layout }
    func currentLayout() -> ScreenLayout { layout }
}

@MainActor
final class FakePointer: PointerState {
    var isLeftButtonPressed = true
    var location: CGPoint = .zero
}

@MainActor
final class FakeSettings: SnapSettingsProvider {
    var snapSettings = SnapSettings()
}

@MainActor
final class SpyFollowUp: SnapFollowUp {
    private(set) var snapped: [(windowID: Int, zone: Zone, screenID: CGDirectDisplayID)] = []
    private(set) var cancelCount = 0

    func windowSnapped(_ window: any WindowHandle, zone: Zone, screen: ScreenInfo) {
        snapped.append(((window as? FakeWindow)?.id ?? -1, zone, screen.id))
    }

    func cancel() { cancelCount += 1 }
}

@MainActor
final class SpyPreview: SnapPreview {
    private(set) var frame: CGRect?
    func show(frame: CGRect) { self.frame = frame }
    func hide() { frame = nil }
}

@MainActor
final class SpyResizeHandler: SnappedWindowResizeHandler {
    private(set) var resized: [(from: CGRect, to: CGRect)] = []
    private(set) var ended = 0
    func windowResized(_ window: any WindowHandle, from old: CGRect, to new: CGRect) { resized.append((old, new)) }
    func resizeEnded(_ window: any WindowHandle) { ended += 1 }
}

@MainActor
final class FakeAssistPresenter: SnapAssistPresenter {
    private(set) var frame: CGRect?
    private(set) var candidates: [SnapAssistCandidate] = []
    private(set) var showsPreviews = false
    private(set) var thumbnails: [Int] = []
    private var onSelect: ((Int) -> Void)?

    var isShown: Bool { frame != nil }

    func show(frame: CGRect, candidates: [SnapAssistCandidate], showsPreviews: Bool,
              onSelect: @escaping (Int) -> Void, onDismiss: @escaping () -> Void) {
        self.frame = frame
        self.candidates = candidates
        self.showsPreviews = showsPreviews
        self.onSelect = onSelect
    }

    func showThumbnail(_ image: CGImage, size: CGSize, for id: Int) { thumbnails.append(id) }

    func hide() {
        frame = nil
        onSelect = nil
    }

    /// Simulates a click on a tile.
    func select(_ id: Int) { onSelect?(id) }
}

@MainActor
final class FakeThumbnails: WindowThumbnails {
    private(set) var requested: [Int] = []
    func capture(_ targets: [(id: Int, window: WindowDescriptor)], maxSize: CGSize,
                 deliver: @escaping @MainActor (Int, CGImage, CGSize) -> Void) async {
        requested = targets.map(\.id)
    }
}

@MainActor
final class FakeScreenRecording: ScreenRecordingAccess {
    var isGranted = false
    func request() -> Bool { isGranted }
    func openSystemSettings() {}
}

@MainActor
final class FakeLauncher: AppLauncher {
    private(set) var launched: [String] = []
    /// Runs when the apps are launched (e.g. adds their windows to the fake window system).
    var onLaunch: () -> Void = {}
    func launch(_ apps: [String]) async {
        launched += apps
        onLaunch()
    }
}

/// The snapping use cases wired on fakes, the way `AppController` wires them on real adapters.
@MainActor
struct SnappingHarness {
    let windows = FakeWindowSystem()
    let displays: FakeDisplays
    let pointer = FakePointer()
    let settings = FakeSettings()
    let followUp = SpyFollowUp()
    let preview = SpyPreview()
    let resizeHandler = SpyResizeHandler()
    let store = SnapStore()
    let manageable: ManageableWindows
    let place: PlaceWindowInZone
    let snap: SnapWindowToZone

    init(layout: ScreenLayout = Fixtures.twoScreens) {
        displays = FakeDisplays(layout)
        manageable = ManageableWindows(windows: windows, settings: settings)
        place = PlaceWindowInZone(store: store, settings: settings)
        snap = SnapWindowToZone(place: place, followUp: followUp)
    }

    func keyboard() -> SnapWithKeyboard {
        SnapWithKeyboard(windows: windows, manageable: manageable, displays: displays, store: store,
                         snap: snap, followUp: followUp, settings: settings)
    }

    func dragSession() -> DragSnapSession {
        DragSnapSession(windows: windows, manageable: manageable, displays: displays, pointer: pointer,
                        store: store, place: place, preview: preview, followUp: followUp,
                        resizeHandler: resizeHandler, settings: settings, readInterval: .zero)
    }

    /// A window on the primary display, frontmost and under the pointer.
    func window(_ id: Int = 1, frame: CGRect = CGRect(x: 300, y: 200, width: 800, height: 600),
                app: String = "Safari") -> FakeWindow {
        let window = FakeWindow(id: id, frame: frame, appName: app, bundleIdentifier: "com.example.\(app)")
        windows.windows.append(window)
        windows.frontmost = window
        windows.underPointer = window
        return window
    }
}

// MARK: Shortcut import

@MainActor
final class FakeShortcutSourceReader: ShortcutSourceReader {
    var preferences: [ShortcutSource: [String: Any]] = [:]
    var files: [ShortcutSource: String] = [:]

    func read(_ source: ShortcutSource) -> ShortcutSourceData? {
        if let values = preferences[source] { return .preferences(values) }
        if let text = files[source] { return .text(text) }
        return nil
    }
}

@MainActor
final class FakeShortcutsStore: ShortcutsStore {
    var shortcuts: [SnapAction: KeyboardShortcut] = SnapAction.defaultShortcuts
}

// MARK: Workspaces

@MainActor
final class FakeWorkspaceStore: WorkspaceStore {
    var saved: [Workspace] = []
    private(set) var saveCount = 0

    func load() throws -> [Workspace] { saved }

    func save(_ workspaces: [Workspace]) throws {
        saved = workspaces
        saveCount += 1
    }
}

@MainActor
final class FakeWindowStacking: WindowStacking {
    var windows: [StackedWindow] = []
    func frontToBack() -> [StackedWindow] { windows }
}

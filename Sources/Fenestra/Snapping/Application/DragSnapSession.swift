import CoreGraphics

/// One window drag, from button press to release: drag snapping with its preview, restoration of
/// the pre-snap size when a snapped window is dragged away, and resizes of snapped windows
/// (handed to the shared border).
@MainActor
final class DragSnapSession {
    private let windows: any WindowSystem
    private let manageable: ManageableWindows
    private let displays: any DisplayProvider
    private let pointer: any PointerState
    private let store: SnapStore
    private let place: PlaceWindowInZone
    private let preview: any SnapPreview
    private let followUp: any SnapFollowUp
    private let resizeHandler: any SnappedWindowResizeHandler
    private let settings: any SnapSettingsProvider
    /// Minimum time between two reads of the dragged window's frame.
    private let readInterval: Duration

    // State of the current drag.
    private var layout = ScreenLayout(screens: [])
    /// Settings read once per drag: nothing is rebuilt on each mouse event.
    private var dragSettings = SnapSettings()
    private var resolver = DragZoneResolver(config: .init())
    private var dragWindow: (any WindowHandle)?
    private var wasSnapped = false
    private var lastFrame: CGRect = .zero
    private var lastRead: ContinuousClock.Instant = .now
    private var didUnsnap = false
    private var didResize = false
    private var pending: (zone: Zone, screen: ScreenInfo)?
    /// Ends the drag if the button release was never delivered (drop over one of our own windows, lost event).
    private var releaseWatchdog: Task<Void, Never>?

    init(windows: any WindowSystem, manageable: ManageableWindows, displays: any DisplayProvider,
         pointer: any PointerState, store: SnapStore, place: PlaceWindowInZone, preview: any SnapPreview,
         followUp: any SnapFollowUp, resizeHandler: any SnappedWindowResizeHandler,
         settings: any SnapSettingsProvider, readInterval: Duration = .milliseconds(16)) {
        self.windows = windows
        self.manageable = manageable
        self.displays = displays
        self.pointer = pointer
        self.store = store
        self.place = place
        self.preview = preview
        self.followUp = followUp
        self.resizeHandler = resizeHandler
        self.settings = settings
        self.readInterval = readInterval
    }

    var isDragging: Bool { dragWindow != nil }

    func mouseDown(at point: CGPoint) {
        // Snap Assist is not dismissed here: clicks on its own tiles reach us through the local
        // monitor, and the panel already closes itself on clicks anywhere else.
        cancel()
        guard let window = windows.window(at: point),
              manageable.isManageable(window), let frame = window.frame else { return }
        layout = displays.currentLayout()
        dragSettings = settings.snapSettings
        resolver = DragZoneResolver(config: dragSettings.dragResolver)
        dragWindow = window
        lastFrame = frame
        lastRead = .now
        wasSnapped = store.isStillSnapped(window, frame: frame)
        startReleaseWatchdog()
    }

    func mouseDragged(at point: CGPoint) {
        guard let window = dragWindow else { return }
        guard pointer.isLeftButtonPressed else {
            mouseUp(at: point)
            return
        }
        let now = ContinuousClock.now
        guard now - lastRead >= readInterval else { return }
        lastRead = now
        guard let frame = window.frame else {
            store.remove(window)
            cancel()
            return
        }
        if abs(frame.width - lastFrame.width) > 1 || abs(frame.height - lastFrame.height) > 1 {
            didResize = true
            pending = nil
            preview.hide()
            if wasSnapped { resizeHandler.windowResized(window, from: lastFrame, to: frame) }
            lastFrame = frame
            return
        }
        guard !didResize, frame.origin != lastFrame.origin else { return }
        var current = frame
        if wasSnapped && dragSettings.restoreOnUnsnap && !didUnsnap {
            didUnsnap = true
            current = unsnap(window, frame: frame, pointer: point) ?? frame
        }
        lastFrame = current
        updatePreview(pointer: point)
    }

    func mouseUp(at point: CGPoint) {
        preview.hide()
        guard let window = dragWindow else { return }
        let resized = didResize
        let wasSnapped = self.wasSnapped
        let target = pending
        cancel()
        if resized {
            if wasSnapped { resizeHandler.resizeEnded(window) }
            return
        }
        guard let (zone, screen) = target else {
            // Dropped outside any zone (restoration off): the window is no longer snapped.
            if wasSnapped, let frame = window.frame, !store.isStillSnapped(window, frame: frame) {
                store.remove(window)
            }
            return
        }
        place.execute(window, zone: zone, on: screen)
        followUp.windowSnapped(window, zone: zone, screen: screen)
    }

    /// Resets the drag state and hides the preview.
    func cancel() {
        preview.hide()
        releaseWatchdog?.cancel()
        releaseWatchdog = nil
        dragWindow = nil
        wasSnapped = false
        didUnsnap = false
        didResize = false
        pending = nil
    }

    private func startReleaseWatchdog() {
        releaseWatchdog?.cancel()
        releaseWatchdog = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self, self.dragWindow != nil else { return }
                if !self.pointer.isLeftButtonPressed {
                    self.mouseUp(at: self.pointer.location)
                    return
                }
            }
        }
    }

    /// Gives the window its pre-snap size back, keeping the pointer at the same place in the title bar.
    private func unsnap(_ window: any WindowHandle, frame: CGRect, pointer: CGPoint) -> CGRect? {
        guard let record = store.remove(window) else { return nil }
        let target = SnapGeometry.unsnappedFrame(restoring: record.restoreFrame.size, from: frame, pointer: pointer)
        return window.setFrame(target) ?? target
    }

    private func updatePreview(pointer: CGPoint) {
        let settings = dragSettings
        guard settings.dragSnapEnabled, let screen = layout.screen(containing: pointer) else { return }
        let zone = resolver.zone(forPointer: pointer, on: screen, innerEdges: layout.innerEdges(of: screen))
            .flatMap { settings.enabledZones.contains($0) ? $0 : nil }
        guard zone != pending?.zone || screen.id != pending?.screen.id else { return }
        guard let zone else {
            pending = nil
            preview.hide()
            return
        }
        pending = (zone, screen)
        preview.show(frame: zone.frame(in: screen.visibleFrame, gap: settings.gap))
    }
}

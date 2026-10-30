import AppKit
import QuartzCore
import os

/// Orchestrates drag snapping, keyboard snapping and restoration.
@MainActor
final class SnapController {
    private static let tolerance: CGFloat = 4
    private static let readInterval: CFTimeInterval = 0.016

    private let settings: Settings
    private let preview = SnapPreviewPanel()
    private let keyboardResolver = KeyboardSnapResolver()
    private(set) var registry = SnapRegistry<AXWindow>()
    var snapAssist: SnapAssistController?
    private(set) lazy var sharedBorder = SharedBorderController(snapController: self)

    // Drag state
    private var layout = ScreenLayout(screens: [])
    private var resolver: DragZoneResolver
    private var dragWindow: AXWindow?
    private var wasSnapped = false
    private var lastFrame: CGRect = .zero
    private var lastReadTime: CFTimeInterval = 0
    private var didUnsnap = false
    private var didResize = false
    private var pending: (zone: Zone, screen: ScreenInfo)?
    /// Ends the drag if the button release was never delivered (drop over one of our own windows, lost event).
    private var releaseWatchdog: Task<Void, Never>?

    init(settings: Settings) {
        self.settings = settings
        resolver = DragZoneResolver(config: settings.dragResolverConfig)
    }

    // MARK: Drag

    func mouseDown(at point: CGPoint) {
        // Snap Assist is not dismissed here: clicks on its own tiles reach us through the local
        // monitor, and the panel already closes itself on clicks anywhere else.
        cancelDrag()
        guard let window = AXWindowFinder.window(at: point),
              isManageable(window), let frame = window.frame else { return }
        layout = .current()
        resolver = DragZoneResolver(config: settings.dragResolverConfig)
        dragWindow = window
        lastFrame = frame
        lastReadTime = CACurrentMediaTime()
        wasSnapped = registry.isStillSnapped(window, frame: frame, tolerance: Self.tolerance)
        startReleaseWatchdog()
    }

    func mouseDragged(at point: CGPoint) {
        guard let window = dragWindow else { return }
        guard DragMonitor.isLeftButtonPressed else {
            mouseUp(at: point)
            return
        }
        let now = CACurrentMediaTime()
        guard now - lastReadTime >= Self.readInterval else { return }
        lastReadTime = now
        guard let frame = window.frame else {
            registry.remove(window)
            cancelDrag()
            return
        }
        if abs(frame.width - lastFrame.width) > 1 || abs(frame.height - lastFrame.height) > 1 {
            didResize = true
            pending = nil
            preview.hide()
            if wasSnapped && settings.sharedBorderEnabled {
                sharedBorder.windowResized(window, from: lastFrame, to: frame)
            }
            lastFrame = frame
            return
        }
        guard !didResize, frame.origin != lastFrame.origin else { return }
        var current = frame
        if wasSnapped && settings.restoreOnUnsnap && !didUnsnap {
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
        cancelDrag()
        if resized {
            if wasSnapped && settings.sharedBorderEnabled { sharedBorder.finishResize(window) }
            return
        }
        guard let (zone, screen) = target else { return }
        place(window, zone: zone, on: screen)
        if settings.snapAssistEnabled, zone.complement != nil {
            snapAssist?.offer(after: window, zone: zone, screen: screen)
        }
    }

    private func startReleaseWatchdog() {
        releaseWatchdog?.cancel()
        releaseWatchdog = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self, self.dragWindow != nil else { return }
                if !DragMonitor.isLeftButtonPressed {
                    self.mouseUp(at: DragMonitor.pointerLocation)
                    return
                }
            }
        }
    }

    /// Resets the drag state and hides the preview.
    func cancelDrag() {
        preview.hide()
        releaseWatchdog?.cancel()
        releaseWatchdog = nil
        dragWindow = nil
        wasSnapped = false
        didUnsnap = false
        didResize = false
        pending = nil
    }

    /// Gives the window its pre-snap size back, keeping the pointer at the same ratio in the title bar.
    private func unsnap(_ window: AXWindow, frame: CGRect, pointer: CGPoint) -> CGRect? {
        guard let record = registry.remove(window) else { return nil }
        let size = record.restoreFrame.size
        let ratio = frame.width > 0 ? min(max((pointer.x - frame.minX) / frame.width, 0), 1) : 0.5
        let offsetY = min(max(pointer.y - frame.minY, 0), 30)
        let target = CGRect(origin: CGPoint(x: pointer.x - ratio * size.width, y: pointer.y - offsetY), size: size)
        return window.setFrame(target) ?? target
    }

    private func updatePreview(pointer: CGPoint) {
        guard let screen = layout.screen(containing: pointer) else { return }
        let zone = resolver.zone(forPointer: pointer, on: screen, innerEdges: layout.innerEdges(of: screen))
            .flatMap { settings.enabledZones.contains($0) ? $0 : nil }
        guard zone != pending?.zone || screen.id != pending?.screen.id else { return }
        guard let zone else {
            pending = nil
            preview.hide()
            return
        }
        pending = (zone, screen)
        preview.show(frame: cocoaFrame(of: zone, on: screen))
    }

    func cocoaFrame(of zone: Zone, on screen: ScreenInfo) -> CGRect {
        ScreenGeometry.toCocoa(zone.frame(in: screen.visibleFrame, gap: CGFloat(settings.gap)),
                               primaryHeight: NSScreen.primaryHeight)
    }

    // MARK: Keyboard

    func perform(_ action: SnapAction) {
        guard let window = AXWindowFinder.frontmostWindow(), isManageable(window),
              let frame = window.frame else { return }
        layout = .current()
        guard let screen = layout.screen(for: frame) else { return }
        var state: WindowSnapState?
        if let record = registry.record(for: window) {
            if registry.isStillSnapped(window, frame: frame, tolerance: Self.tolerance) {
                state = WindowSnapState(zone: record.zone, screenID: record.screenID)
            } else {
                registry.remove(window)
            }
        }
        switch keyboardResolver.command(for: action, state: state, on: screen, layout: layout) {
        case .place(let zone, let target):
            place(window, zone: zone, on: target)
            window.raise()
        case .restore:
            restore(window)
        case .none:
            if state == nil, action == .nextDisplay || action == .previousDisplay {
                moveProportionally(window, frame: frame, from: screen, forward: action == .nextDisplay)
            }
        }
    }

    private func moveProportionally(_ window: AXWindow, frame: CGRect, from screen: ScreenInfo, forward: Bool) {
        guard let target = forward ? layout.next(after: screen) : layout.previous(before: screen) else { return }
        let source = screen.visibleFrame, area = target.visibleFrame
        let width = min(frame.width, area.width), height = min(frame.height, area.height)
        let relX = source.width > 0 ? (frame.minX - source.minX) / source.width : 0
        let relY = source.height > 0 ? (frame.minY - source.minY) / source.height : 0
        let x = min(max(area.minX + relX * area.width, area.minX), area.maxX - width)
        let y = min(max(area.minY + relY * area.height, area.minY), area.maxY - height)
        window.setFrame(CGRect(x: x, y: y, width: width, height: height))
        window.raise()
    }

    // MARK: Placement

    func place(_ window: AXWindow, zone: Zone, on screen: ScreenInfo) {
        guard let current = window.frame else {
            registry.remove(window)
            return
        }
        let target = zone.frame(in: screen.visibleFrame, gap: CGFloat(settings.gap))
        let actual = window.setFrame(target) ?? target
        registry.recordSnap(window, zone: zone, screenID: screen.id, snappedFrame: actual, currentFrame: current)
    }

    /// Placement requested by Snap Assist or the screen watcher (no raise, restore frame preserved).
    func placeExternal(window: AXWindow, zone: Zone, screen: ScreenInfo) {
        place(window, zone: zone, on: screen)
    }

    func restore(_ window: AXWindow) {
        guard let record = registry.remove(window) else { return }
        window.setFrame(record.restoreFrame)
    }

    // MARK: Registry access

    /// Windows still snapped on a screen; records of vanished or moved windows are dropped.
    func snappedWindows(on screenID: CGDirectDisplayID, excluding skipped: AXWindow? = nil) -> [(AXWindow, SnapRecord)] {
        var result: [(AXWindow, SnapRecord)] = []
        for window in registry.keys(on: screenID) where window != skipped {
            guard let frame = window.frame else {
                registry.remove(window)
                continue
            }
            guard let record = registry.record(for: window) else { continue }
            if registry.isStillSnapped(window, frame: frame, tolerance: Self.tolerance) {
                result.append((window, record))
            } else {
                registry.remove(window)
            }
        }
        return result
    }

    func updateSnappedFrame(_ window: AXWindow, to frame: CGRect) {
        registry.updateSnappedFrame(window, to: frame)
    }

    private func isManageable(_ window: AXWindow) -> Bool {
        window.isStandardWindow && !window.isFullScreen
            && !settings.isExcluded(bundleIdentifier: window.bundleIdentifier)
    }
}

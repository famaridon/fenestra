import AppKit

/// Global left-mouse monitor. Reports pointer positions in AX coordinates.
@MainActor
final class DragMonitor {
    var onMouseDown: ((CGPoint) -> Void)?
    var onMouseDragged: ((CGPoint) -> Void)?
    var onMouseUp: ((CGPoint) -> Void)?

    private var monitor: Any?
    private var localMonitor: Any?

    var isRunning: Bool { monitor != nil }

    /// True while the left mouse button is held down.
    static var isLeftButtonPressed: Bool { NSEvent.pressedMouseButtons & 1 != 0 }

    /// Current pointer position in AX coordinates.
    static var pointerLocation: CGPoint {
        ScreenGeometry.toAX(NSEvent.mouseLocation, primaryHeight: NSScreen.primaryHeight)
    }

    func start() {
        guard monitor == nil else { return }
        let mask: NSEvent.EventTypeMask = [.leftMouseDown, .leftMouseDragged, .leftMouseUp]
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            // Global monitors for mouse events are delivered on the main thread.
            let type = event.type
            MainActor.assumeIsolated { self?.handle(type) }
        }
        // Global monitors never see events aimed at our own windows (preview, Snap Assist, settings):
        // a drop over one of them would otherwise never end the drag.
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp]) { [weak self] event in
            let type = event.type
            MainActor.assumeIsolated { self?.handle(type) }
            return event
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        monitor = nil
        localMonitor = nil
    }

    private func handle(_ type: NSEvent.EventType) {
        let point = Self.pointerLocation
        switch type {
        case .leftMouseDown: onMouseDown?(point)
        case .leftMouseDragged: onMouseDragged?(point)
        case .leftMouseUp: onMouseUp?(point)
        default: break
        }
    }
}

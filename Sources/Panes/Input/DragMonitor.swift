import AppKit

/// Global left-mouse monitor. Reports pointer positions in AX coordinates.
@MainActor
final class DragMonitor {
    var onMouseDown: ((CGPoint) -> Void)?
    var onMouseDragged: ((CGPoint) -> Void)?
    var onMouseUp: ((CGPoint) -> Void)?

    private var monitor: Any?

    var isRunning: Bool { monitor != nil }

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]
        ) { [weak self] event in
            // Global monitors for mouse events are delivered on the main thread.
            let type = event.type
            MainActor.assumeIsolated { self?.handle(type) }
        }
    }

    func stop() {
        guard let monitor else { return }
        NSEvent.removeMonitor(monitor)
        self.monitor = nil
    }

    private func handle(_ type: NSEvent.EventType) {
        let point = ScreenGeometry.toAX(NSEvent.mouseLocation, primaryHeight: NSScreen.primaryHeight)
        switch type {
        case .leftMouseDown: onMouseDown?(point)
        case .leftMouseDragged: onMouseDragged?(point)
        case .leftMouseUp: onMouseUp?(point)
        default: break
        }
    }
}

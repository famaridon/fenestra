import AppKit

/// Watches the pointer and runs `ShowSnapLayouts` each time it rests for a moment (none while it moves).
@MainActor
final class ZoomButtonHoverMonitor {
    /// How long the pointer must rest before the button under it is looked up.
    private static let dwell: Duration = .milliseconds(300)

    private let showSnapLayouts: ShowSnapLayouts
    private var moveMonitor: Any?
    private var dwellTask: Task<Void, Never>?

    init(showSnapLayouts: ShowSnapLayouts) {
        self.showSnapLayouts = showSnapLayouts
    }

    func start() {
        guard moveMonitor == nil else { return }
        moveMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            // Global monitors for mouse events are delivered on the main thread.
            MainActor.assumeIsolated { self?.pointerMoved() }
        }
    }

    func stop() {
        if let moveMonitor { NSEvent.removeMonitor(moveMonitor) }
        moveMonitor = nil
        dwellTask?.cancel()
        dwellTask = nil
        showSnapLayouts.dismiss()
    }

    private func pointerMoved() {
        dwellTask?.cancel()
        dwellTask = Task { [weak self] in
            try? await Task.sleep(for: Self.dwell)
            guard !Task.isCancelled else { return }
            self?.showSnapLayouts.execute()
        }
    }
}

/// `ZoomButtonLocator` backed by the Accessibility API.
@MainActor
final class AXZoomButtonLocator: ZoomButtonLocator {
    func zoomButton(at point: CGPoint) -> (window: any WindowHandle, buttonFrame: CGRect)? {
        AXWindowFinder.zoomButton(at: point).map { ($0.window, $0.buttonFrame) }
    }
}

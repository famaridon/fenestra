import AppKit

/// Snap Layouts: when the pointer rests on a window's zoom (green) button, offers a palette of layouts.
@MainActor
final class SnapLayoutsController {
    /// How long the pointer must rest before the button under it is looked up.
    private static let dwell: Duration = .milliseconds(300)

    private let settings: Settings
    private unowned let snapController: SnapController
    private let panel = SnapLayoutsPanel()
    private var moveMonitor: Any?
    private var dwellTask: Task<Void, Never>?
    private var trackTask: Task<Void, Never>?
    /// Zoom button of the window the palette is open for, in Cocoa coordinates.
    private var buttonFrame: CGRect = .zero

    init(settings: Settings, snapController: SnapController) {
        self.settings = settings
        self.snapController = snapController
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
        dismiss()
    }

    func dismiss() {
        trackTask?.cancel()
        trackTask = nil
        panel.hide()
    }

    /// One Accessibility lookup per pause of the pointer, none while it moves.
    private func pointerMoved() {
        dwellTask?.cancel()
        guard !panel.isVisible else { return }
        dwellTask = Task { [weak self] in
            try? await Task.sleep(for: Self.dwell)
            guard !Task.isCancelled else { return }
            self?.showIfOverZoomButton()
        }
    }

    private func showIfOverZoomButton() {
        guard !DragMonitor.isLeftButtonPressed,
              let (window, button) = AXWindowFinder.zoomButton(at: DragMonitor.pointerLocation),
              snapController.isManageable(window), let frame = window.frame,
              let screen = ScreenLayout.current().screen(for: frame) else { return }
        let layouts = SnapLayout.available(for: screen.orientation, enabledZones: settings.enabledZones)
        guard !layouts.isEmpty else { return }
        let primaryHeight = NSScreen.primaryHeight
        buttonFrame = ScreenGeometry.toCocoa(button, primaryHeight: primaryHeight)
        panel.show(layouts: layouts, screenSize: screen.visibleFrame.size, below: buttonFrame,
                   within: ScreenGeometry.toCocoa(screen.visibleFrame, primaryHeight: primaryHeight),
                   onSelect: { [weak self] zone in
                       self?.dismiss()
                       self?.snapController.snap(window, to: zone, on: screen)
                   },
                   onDismiss: { [weak self] in self?.dismiss() })
        trackPointer()
    }

    /// Closes the palette once the pointer has left both the button and the palette for a moment.
    private func trackPointer() {
        trackTask?.cancel()
        trackTask = Task { [weak self] in
            var outside = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self else { return }
                let kept = self.panel.frame.union(self.buttonFrame).insetBy(dx: -8, dy: -8)
                outside = kept.contains(NSEvent.mouseLocation) ? 0 : outside + 1
                if outside >= 3 {
                    self.dismiss()
                    return
                }
            }
        }
    }
}

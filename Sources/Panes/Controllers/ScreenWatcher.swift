import AppKit

/// F7: re-applies every snapped window's zone when the display configuration changes.
@MainActor
final class ScreenWatcher {
    private unowned let snapController: SnapController
    private var observer: (any NSObjectProtocol)?
    private var debounce: Task<Void, Never>?

    init(snapController: SnapController) {
        self.snapController = snapController
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.scheduleReapply() }
        }
    }

    isolated deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        debounce?.cancel()
    }

    private func scheduleReapply() {
        debounce?.cancel()
        debounce = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            self?.reapply()
        }
    }

    private func reapply() {
        let layout = ScreenLayout.current()
        for (window, record) in snapController.registry.records {
            guard let screen = layout.screen(id: record.screenID) ?? layout.screens.first else { continue }
            snapController.placeExternal(window: window, zone: record.zone, screen: screen)
        }
    }
}

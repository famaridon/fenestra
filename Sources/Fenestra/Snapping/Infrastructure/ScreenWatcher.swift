import AppKit

/// Watches the display configuration and re-applies every snapped window's zone when it changes.
@MainActor
final class ScreenWatcher {
    private let reapply: ReapplySnapsAfterDisplayChange
    private var observer: (any NSObjectProtocol)?
    private var debounce: Task<Void, Never>?

    init(reapply: ReapplySnapsAfterDisplayChange) {
        self.reapply = reapply
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
            self?.reapply.execute()
        }
    }
}

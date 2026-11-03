import AppKit

/// Watches the display configuration and, once it settles, runs `onChange` (re-applying the snapped
/// windows' zones, then the workspace saved for these displays).
@MainActor
final class ScreenWatcher {
    private let onChange: @MainActor () async -> Void
    private var observer: (any NSObjectProtocol)?
    private var debounce: Task<Void, Never>?

    init(onChange: @escaping @MainActor () async -> Void) {
        self.onChange = onChange
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.schedule() }
        }
    }

    isolated deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        debounce?.cancel()
    }

    /// macOS posts several notifications per change: act half a second after the last one.
    private func schedule() {
        debounce?.cancel()
        debounce = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled, let self else { return }
            await self.onChange()
        }
    }
}

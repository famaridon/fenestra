import ApplicationServices
import Observation

/// Tracks whether Fenestra is trusted to drive other apps' windows through the Accessibility API.
@MainActor
@Observable
final class AccessibilityPermission {
    /// Current trust state, readable without an instance.
    nonisolated static var isTrusted: Bool { AXIsProcessTrusted() }

    private(set) var isGranted = AXIsProcessTrusted()
    private var pollTask: Task<Void, Never>?

    init() {
        // macOS doesn't notify when the user toggles the permission, so poll until granted.
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                self.isGranted = AXIsProcessTrusted()
                if self.isGranted { return }
            }
        }
    }

    /// Shows the system prompt that opens System Settings > Privacy & Security > Accessibility.
    func request() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        isGranted = AXIsProcessTrustedWithOptions(options)
    }
}

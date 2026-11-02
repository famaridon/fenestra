import Observation

/// Whether the system trusts Fenestra to drive other apps' windows (port).
@MainActor
protocol AccessibilityTrust: AnyObject {
    var isTrusted: Bool { get }
    /// Shows the system prompt that opens System Settings > Privacy & Security > Accessibility;
    /// returns the trust state.
    func requestTrust() -> Bool
}

/// Tracks whether Fenestra is trusted to drive other apps' windows through the Accessibility API.
@MainActor
@Observable
final class AccessibilityPermission {
    @ObservationIgnored private let trust: any AccessibilityTrust
    private(set) var isGranted: Bool
    @ObservationIgnored private var pollTask: Task<Void, Never>?

    init(trust: any AccessibilityTrust) {
        self.trust = trust
        isGranted = trust.isTrusted
        // macOS doesn't notify when the user toggles the permission, so poll until granted.
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                self.isGranted = self.trust.isTrusted
                if self.isGranted { return }
            }
        }
    }

    func request() {
        isGranted = trust.requestTrust()
    }
}

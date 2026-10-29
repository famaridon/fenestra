import AppKit

extension Notification.Name {
    /// Posted when the welcome window should be shown (first launch or missing permission).
    static let panesShowOnboarding = Notification.Name("com.florentamaridon.Panes.showOnboarding")
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if !Settings.shared.hasCompletedOnboarding || !AccessibilityPermission.isTrusted {
            NSApp.activate(ignoringOtherApps: true)
            NotificationCenter.default.post(name: .panesShowOnboarding, object: nil)
        }
    }
}

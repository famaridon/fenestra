import AppKit

extension Notification.Name {
    /// Posted when the welcome window should be shown (first launch or missing permission).
    static let fenestraShowOnboarding = Notification.Name("com.florentamaridon.Fenestra.showOnboarding")
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if !Settings.shared.hasCompletedOnboarding || !AccessibilityPermission.isTrusted {
            NSApp.activate(ignoringOtherApps: true)
            NotificationCenter.default.post(name: .fenestraShowOnboarding, object: nil)
        }
    }
}

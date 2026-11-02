import AppKit
import CoreGraphics

/// Screen Recording permission, needed only for the window thumbnails in Snap Assist.
@MainActor
final class ScreenRecordingPermission: ScreenRecordingAccess {
    var isGranted: Bool { CGPreflightScreenCaptureAccess() }

    /// Shows the system prompt the first time, and adds Fenestra to the list in System Settings.
    @discardableResult
    func request() -> Bool { CGRequestScreenCaptureAccess() }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
        else { return }
        NSWorkspace.shared.open(url)
    }
}

import CoreGraphics
import Foundation

/// A window of another application, as the use cases see it (port).
/// Frames are in AX coordinates. Equality identifies the same window, even across two handles.
@MainActor
protocol WindowHandle: AnyObject, Hashable, Sendable {
    /// Process of the owning application.
    nonisolated var pid: pid_t { get }
    /// Current frame, or nil if it cannot be read (window closed, app unresponsive).
    var frame: CGRect? { get }
    /// Moves and resizes the window; returns the frame actually obtained, or nil on error.
    @discardableResult func setFrame(_ frame: CGRect) -> CGRect?
    /// Raises the window and activates its application.
    func raise()

    var title: String? { get }
    var appName: String? { get }
    var bundleIdentifier: String? { get }
    var isStandardWindow: Bool { get }
    var isFullScreen: Bool { get }
    var isResizable: Bool { get }
}

/// Hashable box around any window, to key dictionaries and sets.
struct WindowRef: Hashable, Sendable {
    let window: any WindowHandle

    init(_ window: any WindowHandle) {
        self.window = window
    }

    static func == (lhs: WindowRef, rhs: WindowRef) -> Bool {
        AnyHashable(lhs.window) == AnyHashable(rhs.window)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(AnyHashable(window))
    }
}

extension WindowHandle {
    /// Same window, whatever the concrete handle types.
    func isSame(as other: any WindowHandle) -> Bool {
        WindowRef(self) == WindowRef(other)
    }
}

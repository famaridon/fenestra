import CoreGraphics

/// Finds the windows of other applications (port).
@MainActor
protocol WindowSystem: AnyObject {
    /// Focused window of the frontmost application.
    func frontmostWindow() -> (any WindowHandle)?
    /// Window under `point` (AX coordinates).
    func window(at point: CGPoint) -> (any WindowHandle)?
    /// Non-minimized standard windows of every regular application except Fenestra.
    func visibleStandardWindows() -> [any WindowHandle]
}

/// The connected displays (port).
@MainActor
protocol DisplayProvider: AnyObject {
    func currentLayout() -> ScreenLayout
}

/// State of the mouse pointer (port).
@MainActor
protocol PointerState: AnyObject {
    var isLeftButtonPressed: Bool { get }
    /// Current position in AX coordinates.
    var location: CGPoint { get }
}

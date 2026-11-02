import CoreGraphics

/// Finds the zoom (green) button under the pointer (port).
@MainActor
protocol ZoomButtonLocator: AnyObject {
    /// Window whose zoom button is under `point`, with the button's frame (AX coordinates).
    func zoomButton(at point: CGPoint) -> (window: any WindowHandle, buttonFrame: CGRect)?
}

/// The Snap Layouts palette (port).
@MainActor
protocol SnapLayoutsPresenter: AnyObject {
    var isVisible: Bool { get }
    /// Shows the palette under `button`, inside `area` (the visible frame of the window's display);
    /// both in AX coordinates. The palette closes itself on Escape, on a click elsewhere or once the
    /// pointer has left it, and then calls `onDismiss`.
    func show(layouts: [SnapLayout], below button: CGRect, within area: CGRect,
              onSelect: @escaping (Zone) -> Void, onDismiss: @escaping () -> Void)
    func hide()
}

import CoreGraphics

/// Gives the current snapping settings (port).
@MainActor
protocol SnapSettingsProvider: AnyObject {
    var snapSettings: SnapSettings { get }
}

/// Translucent preview of the zone a dragged window will land in (port).
@MainActor
protocol SnapPreview: AnyObject {
    /// `frame` is in AX coordinates.
    func show(frame: CGRect)
    func hide()
}

/// What happens after a snap by the user, Snap Assist in practice (port, implemented by another feature).
@MainActor
protocol SnapFollowUp: AnyObject {
    /// A window was snapped by a drag, a hotkey or the Snap Layouts palette.
    func windowSnapped(_ window: any WindowHandle, zone: Zone, screen: ScreenInfo)
    /// A new snap action starts: a pending offer is withdrawn.
    func cancel()
}

/// Reacts to the resize of a snapped window by the user, the shared border in practice
/// (port, implemented by another feature).
@MainActor
protocol SnappedWindowResizeHandler: AnyObject {
    /// Called while the user drags an edge of a snapped window.
    func windowResized(_ window: any WindowHandle, from old: CGRect, to new: CGRect)
    /// Called once the button is released.
    func resizeEnded(_ window: any WindowHandle)
}

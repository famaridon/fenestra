import AppKit

extension ScreenGeometry {
    /// Converts an AX rect to Cocoa against the current primary display (panels are placed in Cocoa).
    @MainActor
    static func toCocoa(_ rect: CGRect) -> CGRect {
        toCocoa(rect, primaryHeight: NSScreen.screens.first?.frame.height ?? 0)
    }
}

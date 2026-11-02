import AppKit

extension NSScreen {
    /// Height of the primary display, the reference for Cocoa <-> AX conversion.
    @MainActor static var primaryHeight: CGFloat {
        screens.first?.frame.height ?? 0
    }
}

extension ScreenInfo {
    /// Builds a display description in AX coordinates from an `NSScreen`.
    @MainActor
    init(screen: NSScreen, primaryHeight: CGFloat) {
        let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        self.init(
            id: CGDirectDisplayID(number?.uint32Value ?? 0),
            frame: ScreenGeometry.toAX(screen.frame, primaryHeight: primaryHeight),
            visibleFrame: ScreenGeometry.toAX(screen.visibleFrame, primaryHeight: primaryHeight)
        )
    }
}

/// The connected displays, read from `NSScreen`.
@MainActor
final class NSScreenDisplays: DisplayProvider {
    func currentLayout() -> ScreenLayout {
        let primaryHeight = NSScreen.primaryHeight
        return ScreenLayout(screens: NSScreen.screens.map { ScreenInfo(screen: $0, primaryHeight: primaryHeight) })
    }
}

/// Mouse pointer state, read from `NSEvent`.
@MainActor
final class SystemPointer: PointerState {
    var isLeftButtonPressed: Bool { NSEvent.pressedMouseButtons & 1 != 0 }

    var location: CGPoint {
        ScreenGeometry.toAX(NSEvent.mouseLocation, primaryHeight: NSScreen.primaryHeight)
    }
}

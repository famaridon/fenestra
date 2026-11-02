import CoreGraphics
import Foundation

enum ScreenOrientation: String, Sendable, Codable {
    case landscape, portrait
}

enum Direction: Sendable {
    case left, right, up, down
}

/// A display, described in AX coordinates (origin top-left of the primary display, y down).
struct ScreenInfo: Hashable, Sendable, Identifiable {
    let id: CGDirectDisplayID
    /// Full frame of the display.
    let frame: CGRect
    /// Frame minus menu bar and Dock.
    let visibleFrame: CGRect

    init(id: CGDirectDisplayID, frame: CGRect, visibleFrame: CGRect) {
        self.id = id
        self.frame = frame
        self.visibleFrame = visibleFrame
    }

    var orientation: ScreenOrientation {
        frame.height > frame.width ? .portrait : .landscape
    }

    var isPortrait: Bool { orientation == .portrait }
}

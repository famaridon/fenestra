import CoreGraphics

/// The only place where Cocoa coordinates (origin bottom-left of the primary display, y up)
/// are converted to AX coordinates (origin top-left of the primary display, y down) and back.
/// `primaryHeight` is the height of `NSScreen.screens[0].frame`.
enum ScreenGeometry {
    static func toAX(_ rect: CGRect, primaryHeight: CGFloat) -> CGRect {
        CGRect(x: rect.minX, y: primaryHeight - rect.maxY, width: rect.width, height: rect.height)
    }

    static func toCocoa(_ rect: CGRect, primaryHeight: CGFloat) -> CGRect {
        // The transform is an involution: the same formula goes both ways.
        CGRect(x: rect.minX, y: primaryHeight - rect.maxY, width: rect.width, height: rect.height)
    }

    static func toAX(_ point: CGPoint, primaryHeight: CGFloat) -> CGPoint {
        CGPoint(x: point.x, y: primaryHeight - point.y)
    }

    static func toCocoa(_ point: CGPoint, primaryHeight: CGFloat) -> CGPoint {
        CGPoint(x: point.x, y: primaryHeight - point.y)
    }
}

import CoreGraphics
import Foundation

/// What identifies a window across APIs: Accessibility and ScreenCaptureKit share no public window ID.
struct WindowDescriptor: Sendable, Equatable {
    let pid: pid_t
    /// Frame in AX coordinates (origin top-left of the primary screen, y pointing down).
    let frame: CGRect
    let title: String?
}

/// Pairs an Accessibility window with a ScreenCaptureKit window (pure, testable).
enum WindowMatcher {
    /// The candidate with the same process and the same frame (within `tolerance` points);
    /// among several, the one with the same title wins, otherwise the first one.
    static func bestMatch<ID>(for target: WindowDescriptor, among candidates: [(id: ID, window: WindowDescriptor)],
                              tolerance: CGFloat = 2) -> ID? {
        let sameWindow = candidates.filter {
            $0.window.pid == target.pid && framesMatch($0.window.frame, target.frame, tolerance: tolerance)
        }
        return (sameWindow.first { $0.window.title == target.title } ?? sameWindow.first)?.id
    }

    private static func framesMatch(_ a: CGRect, _ b: CGRect, tolerance: CGFloat) -> Bool {
        abs(a.minX - b.minX) <= tolerance && abs(a.minY - b.minY) <= tolerance
            && abs(a.width - b.width) <= tolerance && abs(a.height - b.height) <= tolerance
    }
}

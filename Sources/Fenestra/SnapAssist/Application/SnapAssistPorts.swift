import CoreGraphics
import Foundation

/// A window offered by Snap Assist.
struct SnapAssistCandidate: Identifiable, Sendable, Equatable {
    let id: Int
    let title: String
    let appName: String
    /// Owning process, for the app icon.
    let pid: pid_t
}

/// The Snap Assist panel (port).
@MainActor
protocol SnapAssistPresenter: AnyObject {
    /// Shows the candidates in `frame` (AX coordinates). The panel closes itself on Escape or a click
    /// elsewhere and then calls `onDismiss`; it calls `onSelect` with the id of a chosen candidate.
    func show(frame: CGRect, candidates: [SnapAssistCandidate], showsPreviews: Bool,
              onSelect: @escaping (Int) -> Void, onDismiss: @escaping () -> Void)
    /// Thumbnail of a candidate, `size` in points.
    func showThumbnail(_ image: CGImage, size: CGSize, for id: Int)
    func hide()
}

/// Window thumbnails (port).
@MainActor
protocol WindowThumbnails: AnyObject {
    /// Captures each target it can see, fitting it in `maxSize` points, and hands every image
    /// (with its size in points) to `deliver` as soon as it is ready.
    func capture(_ targets: [(id: Int, window: WindowDescriptor)], maxSize: CGSize,
                 deliver: @escaping @MainActor (Int, CGImage, CGSize) -> Void) async
}

/// The Screen Recording permission, needed only for the thumbnails (port).
@MainActor
protocol ScreenRecordingAccess: AnyObject {
    var isGranted: Bool { get }
    /// Shows the system prompt the first time; returns whether access is granted.
    @discardableResult func request() -> Bool
    func openSystemSettings()
}

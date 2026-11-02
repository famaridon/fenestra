import CoreGraphics

/// The snapped windows of the session: what was snapped where, and the frame to give back.
/// Shared by every use case that places or reads snapped windows.
@MainActor
final class SnapStore {
    /// A window still counts as snapped while each edge is within this distance of its snapped frame.
    static let tolerance: CGFloat = 4

    private var registry = SnapRegistry<WindowRef>()

    init() {}

    func record(for window: any WindowHandle) -> SnapRecord? {
        registry.record(for: WindowRef(window))
    }

    func isStillSnapped(_ window: any WindowHandle, frame: CGRect) -> Bool {
        registry.isStillSnapped(WindowRef(window), frame: frame, tolerance: Self.tolerance)
    }

    /// Record of a window whose `frame` still matches its snapped frame; a stale record is dropped.
    func currentRecord(for window: any WindowHandle, frame: CGRect) -> SnapRecord? {
        guard let record = record(for: window) else { return nil }
        guard isStillSnapped(window, frame: frame) else {
            remove(window)
            return nil
        }
        return record
    }

    func recordSnap(_ window: any WindowHandle, zone: Zone, screenID: CGDirectDisplayID,
                    snappedFrame: CGRect, currentFrame: CGRect) {
        registry.recordSnap(WindowRef(window), zone: zone, screenID: screenID,
                            snappedFrame: snappedFrame, currentFrame: currentFrame)
    }

    func updateSnappedFrame(_ window: any WindowHandle, to frame: CGRect) {
        registry.updateSnappedFrame(WindowRef(window), to: frame)
    }

    @discardableResult
    func remove(_ window: any WindowHandle) -> SnapRecord? {
        registry.remove(WindowRef(window))
    }

    /// Every record, without checking the windows.
    var all: [(window: any WindowHandle, record: SnapRecord)] {
        registry.records.map { ($0.key.window, $0.value) }
    }

    /// Windows still snapped on a screen; records of vanished or moved windows are dropped.
    func snappedWindows(on screenID: CGDirectDisplayID,
                        excluding skipped: (any WindowHandle)? = nil) -> [(window: any WindowHandle, record: SnapRecord)] {
        var result: [(window: any WindowHandle, record: SnapRecord)] = []
        for key in registry.keys(on: screenID) {
            let window = key.window
            if let skipped, window.isSame(as: skipped) { continue }
            guard let frame = window.frame else {
                remove(window)
                continue
            }
            if let record = currentRecord(for: window, frame: frame) { result.append((window, record)) }
        }
        return result
    }
}

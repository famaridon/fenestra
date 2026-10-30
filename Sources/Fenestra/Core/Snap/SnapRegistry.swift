import CoreGraphics
import Foundation

/// What Fenestra remembers about a snapped window.
struct SnapRecord: Sendable, Equatable {
    var zone: Zone
    var screenID: CGDirectDisplayID
    /// Frame actually obtained after the snap (read back from the window).
    var snappedFrame: CGRect
    /// Frame before the first snap, given back on unsnap (F2).
    var restoreFrame: CGRect
}

/// Memory of snapped windows, keyed by whatever identifies a window.
struct SnapRegistry<Key: Hashable & Sendable>: Sendable {
    private(set) var records: [Key: SnapRecord] = [:]

    init() {}

    /// Records a snap. If the key was already snapped, the original `restoreFrame` is kept.
    mutating func recordSnap(_ key: Key, zone: Zone, screenID: CGDirectDisplayID, snappedFrame: CGRect, currentFrame: CGRect) {
        let restore = records[key]?.restoreFrame ?? currentFrame
        records[key] = SnapRecord(zone: zone, screenID: screenID, snappedFrame: snappedFrame, restoreFrame: restore)
    }

    /// Updates the snapped frame (after a shared-border resize).
    mutating func updateSnappedFrame(_ key: Key, to frame: CGRect) {
        records[key]?.snappedFrame = frame
    }

    @discardableResult
    mutating func remove(_ key: Key) -> SnapRecord? {
        records.removeValue(forKey: key)
    }

    func record(for key: Key) -> SnapRecord? {
        records[key]
    }

    func keys(on screenID: CGDirectDisplayID) -> [Key] {
        records.filter { $0.value.screenID == screenID }.map(\.key)
    }

    /// True if `frame` still matches the snapped frame, within `tolerance` points on every edge.
    func isStillSnapped(_ key: Key, frame: CGRect, tolerance: CGFloat) -> Bool {
        guard let snapped = records[key]?.snappedFrame else { return false }
        return abs(frame.minX - snapped.minX) <= tolerance
            && abs(frame.minY - snapped.minY) <= tolerance
            && abs(frame.maxX - snapped.maxX) <= tolerance
            && abs(frame.maxY - snapped.maxY) <= tolerance
    }
}

import CoreGraphics
import Testing
@testable import Panes

struct SnapRegistryTests {
    let original = CGRect(x: 300, y: 200, width: 640, height: 480)
    let left = CGRect(x: 0, y: 0, width: 960, height: 1080)
    let topLeft = CGRect(x: 0, y: 0, width: 960, height: 540)

    @Test func recordAndLookup() {
        var registry = SnapRegistry<String>()
        registry.recordSnap("a", zone: .leftHalf, screenID: 1, snappedFrame: left, currentFrame: original)
        let record = registry.record(for: "a")
        #expect(record == SnapRecord(zone: .leftHalf, screenID: 1, snappedFrame: left, restoreFrame: original))
        #expect(registry.record(for: "b") == nil)
    }

    @Test func restoreFramePreservedAcrossChainedSnaps() {
        var registry = SnapRegistry<String>()
        registry.recordSnap("a", zone: .leftHalf, screenID: 1, snappedFrame: left, currentFrame: original)
        // Second snap: the "current" frame is now the snapped one, it must not become the restore frame.
        registry.recordSnap("a", zone: .topLeft, screenID: 1, snappedFrame: topLeft, currentFrame: left)
        let record = registry.record(for: "a")
        #expect(record?.restoreFrame == original)
        #expect(record?.zone == .topLeft)
        #expect(record?.snappedFrame == topLeft)
    }

    @Test func restoreFrameIsRenewedAfterRemove() {
        var registry = SnapRegistry<String>()
        registry.recordSnap("a", zone: .leftHalf, screenID: 1, snappedFrame: left, currentFrame: original)
        let removed = registry.remove("a")
        #expect(removed?.restoreFrame == original)
        #expect(registry.record(for: "a") == nil)
        registry.recordSnap("a", zone: .rightHalf, screenID: 1, snappedFrame: left, currentFrame: topLeft)
        #expect(registry.record(for: "a")?.restoreFrame == topLeft)
        #expect(registry.remove("zzz") == nil)
    }

    @Test func updateSnappedFrame() {
        var registry = SnapRegistry<Int>()
        registry.recordSnap(1, zone: .leftHalf, screenID: 1, snappedFrame: left, currentFrame: original)
        let wider = CGRect(x: 0, y: 0, width: 1100, height: 1080)
        registry.updateSnappedFrame(1, to: wider)
        #expect(registry.record(for: 1)?.snappedFrame == wider)
        #expect(registry.record(for: 1)?.restoreFrame == original)
        // Unknown key: no record created.
        registry.updateSnappedFrame(2, to: wider)
        #expect(registry.record(for: 2) == nil)
    }

    @Test func keysOnScreen() {
        var registry = SnapRegistry<Int>()
        registry.recordSnap(1, zone: .leftHalf, screenID: 1, snappedFrame: left, currentFrame: original)
        registry.recordSnap(2, zone: .rightHalf, screenID: 1, snappedFrame: left, currentFrame: original)
        registry.recordSnap(3, zone: .topHalf, screenID: 2, snappedFrame: left, currentFrame: original)
        #expect(Set(registry.keys(on: 1)) == [1, 2])
        #expect(registry.keys(on: 2) == [3])
        #expect(registry.keys(on: 9).isEmpty)
    }

    @Test func isStillSnappedHonoursTolerance() {
        var registry = SnapRegistry<String>()
        registry.recordSnap("a", zone: .leftHalf, screenID: 1, snappedFrame: left, currentFrame: original)
        #expect(registry.isStillSnapped("a", frame: left, tolerance: 0))
        #expect(registry.isStillSnapped("a", frame: left.offsetBy(dx: 2, dy: -2), tolerance: 2))
        #expect(!registry.isStillSnapped("a", frame: left.offsetBy(dx: 3, dy: 0), tolerance: 2))
        #expect(!registry.isStillSnapped("a", frame: CGRect(x: 0, y: 0, width: 970, height: 1080), tolerance: 5))
        #expect(registry.isStillSnapped("a", frame: CGRect(x: 0, y: 0, width: 964, height: 1080), tolerance: 5))
        #expect(!registry.isStillSnapped("missing", frame: left, tolerance: 100))
    }
}

import CoreGraphics
import Testing
@testable import Fenestra

@MainActor
struct PropagateBorderResizeTests {
    let harness = SnappingHarness()

    /// Two windows snapped side by side; the left one is widened by 100 points.
    private func widenLeft(_ propagate: PropagateBorderResize) -> (left: FakeWindow, right: FakeWindow) {
        let left = harness.window(1)
        let right = harness.window(2)
        harness.place.execute(left, zone: .leftHalf, on: Fixtures.primary)
        harness.place.execute(right, zone: .rightHalf, on: Fixtures.primary)
        let old = CGRect(x: 0, y: 25, width: 960, height: 1055)
        let new = CGRect(x: 0, y: 25, width: 1060, height: 1055)
        left.frame = new
        propagate.windowResized(left, from: old, to: new)
        return (left, right)
    }

    @Test func theNeighbourFollowsTheSharedBorder() {
        let propagate = PropagateBorderResize(store: harness.store, settings: harness.settings)
        let (left, right) = widenLeft(propagate)
        #expect(right.frame == CGRect(x: 1060, y: 25, width: 860, height: 1055))
        #expect(harness.store.record(for: right)?.snappedFrame == right.frame)

        propagate.resizeEnded(left)
        #expect(harness.store.record(for: left)?.snappedFrame == left.frame)
    }

    @Test func nothingMovesWhenTheSharedBorderIsOff() {
        harness.settings.snapSettings.sharedBorderEnabled = false
        let propagate = PropagateBorderResize(store: harness.store, settings: harness.settings)
        let (_, right) = widenLeft(propagate)
        #expect(right.frame == CGRect(x: 960, y: 25, width: 960, height: 1055))
    }
}

struct SharedBorderGeometryTests {
    @Test func shiftsOnlyTheEdgesThatSatOnTheMovedEdge() {
        let old = CGRect(x: 0, y: 0, width: 500, height: 1000)
        let new = CGRect(x: 0, y: 0, width: 600, height: 1000)
        let below = CGRect(x: 0, y: 1000, width: 500, height: 500)
        #expect(SharedBorderGeometry.shifted(below, old: old, new: new, tolerance: 4)
                == CGRect(x: 0, y: 1000, width: 600, height: 500))
        let apart = CGRect(x: 1000, y: 0, width: 300, height: 300)
        #expect(SharedBorderGeometry.shifted(apart, old: old, new: new, tolerance: 4) == nil)
    }

    @Test func pullsTheChangedWindowBackOntoTheRealEdge() {
        let changed = CGRect(x: 0, y: 0, width: 600, height: 1000)
        let requested = CGRect(x: 600, y: 0, width: 400, height: 1000)
        let actual = CGRect(x: 650, y: 0, width: 350, height: 1000)
        #expect(SharedBorderGeometry.corrected(changed, requested: requested, actual: actual, gap: 0)
                == CGRect(x: 0, y: 0, width: 650, height: 1000))
    }
}

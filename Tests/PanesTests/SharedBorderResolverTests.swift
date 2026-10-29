import CoreGraphics
import Testing
@testable import Panes

struct SharedBorderResolverTests {
    typealias Adjustments = [BorderAdjustment<String>]

    private func window(_ id: String, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
                        min: CGSize = .zero) -> BorderWindow<String> {
        BorderWindow(id: id, frame: CGRect(x: x, y: y, width: w, height: h), minSize: min)
    }

    private func resolve(old: CGRect, new: CGRect, neighbours: [BorderWindow<String>],
                         minChanged: CGSize = .zero, tolerance: CGFloat = 4) -> Adjustments {
        SharedBorderResolver.adjustments(changed: "A", oldFrame: old, newFrame: new, neighbours: neighbours,
                                         minSizeOfChanged: minChanged, tolerance: tolerance)
    }

    private func frame(of id: String, in adjustments: Adjustments) -> CGRect? {
        adjustments.first { $0.id == id }?.frame
    }

    // Screen 1000x800: A = left half, B = right half.
    let leftHalf = CGRect(x: 0, y: 0, width: 500, height: 800)

    @Test func widenLeftWindowShrinksRightNeighbour() {
        let b = window("B", 500, 0, 500, 800)
        let result = resolve(old: leftHalf, new: CGRect(x: 0, y: 0, width: 600, height: 800), neighbours: [b])
        #expect(result == [BorderAdjustment(id: "B", frame: CGRect(x: 600, y: 0, width: 400, height: 800))])
    }

    @Test func shrinkLeftWindowWidensRightNeighbour() {
        let b = window("B", 500, 0, 500, 800)
        let result = resolve(old: leftHalf, new: CGRect(x: 0, y: 0, width: 400, height: 800), neighbours: [b])
        #expect(result == [BorderAdjustment(id: "B", frame: CGRect(x: 400, y: 0, width: 600, height: 800))])
    }

    @Test func draggingLeftEdgeOfRightWindowMovesLeftNeighbourEdge() {
        let a = window("A", 0, 0, 500, 800)
        let old = CGRect(x: 500, y: 0, width: 500, height: 800)
        let result = SharedBorderResolver.adjustments(
            changed: "B", oldFrame: old, newFrame: CGRect(x: 350, y: 0, width: 650, height: 800),
            neighbours: [a], minSizeOfChanged: .zero, tolerance: 4)
        #expect(result == [BorderAdjustment(id: "A", frame: CGRect(x: 0, y: 0, width: 350, height: 800))])
    }

    @Test func verticalPairOfQuarters() {
        let old = CGRect(x: 0, y: 0, width: 500, height: 400)
        let bottomLeft = window("B", 0, 400, 500, 400)
        let down = resolve(old: old, new: CGRect(x: 0, y: 0, width: 500, height: 500), neighbours: [bottomLeft])
        #expect(down == [BorderAdjustment(id: "B", frame: CGRect(x: 0, y: 500, width: 500, height: 300))])
        let up = resolve(old: old, new: CGRect(x: 0, y: 0, width: 500, height: 250), neighbours: [bottomLeft])
        #expect(up == [BorderAdjustment(id: "B", frame: CGRect(x: 0, y: 250, width: 500, height: 550))])
    }

    @Test func topEdgeOfBottomQuarterMovesTopQuarter() {
        let topLeft = window("T", 0, 0, 500, 400)
        let old = CGRect(x: 0, y: 400, width: 500, height: 400)
        let result = SharedBorderResolver.adjustments(
            changed: "A", oldFrame: old, newFrame: CGRect(x: 0, y: 300, width: 500, height: 500),
            neighbours: [topLeft], minSizeOfChanged: .zero, tolerance: 4)
        #expect(result == [BorderAdjustment(id: "T", frame: CGRect(x: 0, y: 0, width: 500, height: 300))])
    }

    @Test func minSizeClampPropagatesBackToChangedWindow() {
        let b = window("B", 500, 0, 500, 800, min: CGSize(width: 300, height: 100))
        let result = resolve(old: leftHalf, new: CGRect(x: 0, y: 0, width: 800, height: 800), neighbours: [b])
        #expect(frame(of: "B", in: result) == CGRect(x: 700, y: 0, width: 300, height: 800))
        #expect(frame(of: "A", in: result) == CGRect(x: 0, y: 0, width: 700, height: 800))
        #expect(result.count == 2)
    }

    @Test func verticalMinSizeClamp() {
        let b = window("B", 0, 400, 500, 400, min: CGSize(width: 0, height: 200))
        let old = CGRect(x: 0, y: 0, width: 500, height: 400)
        let result = resolve(old: old, new: CGRect(x: 0, y: 0, width: 500, height: 700), neighbours: [b])
        #expect(frame(of: "B", in: result) == CGRect(x: 0, y: 600, width: 500, height: 200))
        #expect(frame(of: "A", in: result) == CGRect(x: 0, y: 0, width: 500, height: 600))
    }

    @Test func minSizeOfChangedWindowIsRespected() {
        let b = window("B", 500, 0, 500, 800)
        let result = resolve(old: leftHalf, new: CGRect(x: 0, y: 0, width: 100, height: 800), neighbours: [b],
                             minChanged: CGSize(width: 300, height: 0))
        #expect(frame(of: "A", in: result) == CGRect(x: 0, y: 0, width: 300, height: 800))
        #expect(frame(of: "B", in: result) == CGRect(x: 300, y: 0, width: 700, height: 800))
    }

    @Test func mostConstrainedNeighbourWinsWhenSeveralAreAttached() {
        let topRight = window("T", 500, 0, 500, 400, min: CGSize(width: 200, height: 0))
        let bottomRight = window("U", 500, 400, 500, 400, min: CGSize(width: 400, height: 0))
        let result = resolve(old: leftHalf, new: CGRect(x: 0, y: 0, width: 900, height: 800),
                             neighbours: [topRight, bottomRight])
        // Limit = 1000 - 400 = 600, applied to both neighbours and to the changed window.
        #expect(frame(of: "A", in: result) == CGRect(x: 0, y: 0, width: 600, height: 800))
        #expect(frame(of: "T", in: result) == CGRect(x: 600, y: 0, width: 400, height: 400))
        #expect(frame(of: "U", in: result) == CGRect(x: 600, y: 400, width: 400, height: 400))
    }

    @Test func nonAdjacentWindowsAreUntouched() {
        let b = window("B", 500, 0, 500, 400)
        let apart = window("C", 700, 400, 300, 400)         // no shared border
        let sameXNoOverlap = window("D", 500, 400, 500, 400) // starts at the border but below A's range
        let old = CGRect(x: 0, y: 0, width: 500, height: 400)
        let result = resolve(old: old, new: CGRect(x: 0, y: 0, width: 600, height: 400),
                             neighbours: [b, apart, sameXNoOverlap])
        #expect(result == [BorderAdjustment(id: "B", frame: CGRect(x: 600, y: 0, width: 400, height: 400))])
    }

    @Test func threeWindowsSharingOneBorder() {
        let topRight = window("T", 500, 0, 500, 400)
        let bottomRight = window("U", 500, 400, 500, 400)
        let result = resolve(old: leftHalf, new: CGRect(x: 0, y: 0, width: 650, height: 800),
                             neighbours: [topRight, bottomRight])
        #expect(result.count == 2)
        #expect(frame(of: "T", in: result) == CGRect(x: 650, y: 0, width: 350, height: 400))
        #expect(frame(of: "U", in: result) == CGRect(x: 650, y: 400, width: 350, height: 400))
    }

    @Test func toleranceAllowsSmallGaps() {
        let b = window("B", 503, 0, 497, 800)
        let result = resolve(old: leftHalf, new: CGRect(x: 0, y: 0, width: 600, height: 800), neighbours: [b], tolerance: 4)
        #expect(frame(of: "B", in: result) == CGRect(x: 600, y: 0, width: 400, height: 800))
        let strict = resolve(old: leftHalf, new: CGRect(x: 0, y: 0, width: 600, height: 800), neighbours: [b], tolerance: 1)
        #expect(strict.isEmpty)
    }

    @Test func gapsBetweenWindowsAreNotSnappedAwayBeyondTolerance() {
        // With a 10 pt gap the neighbour is not attached at a 4 pt tolerance.
        let b = window("B", 510, 0, 490, 800)
        #expect(resolve(old: leftHalf, new: CGRect(x: 0, y: 0, width: 600, height: 800), neighbours: [b]).isEmpty)
    }

    @Test func unchangedOrTinyChangesProduceNothing() {
        let b = window("B", 500, 0, 500, 800)
        #expect(resolve(old: leftHalf, new: leftHalf, neighbours: [b]).isEmpty)
        #expect(resolve(old: leftHalf, new: CGRect(x: 0, y: 0, width: 500.3, height: 800), neighbours: [b]).isEmpty)
    }

    @Test func changedWindowInNeighbourListIsIgnored() {
        let a = window("A", 0, 0, 500, 800)
        let b = window("B", 500, 0, 500, 800)
        let result = resolve(old: leftHalf, new: CGRect(x: 0, y: 0, width: 600, height: 800), neighbours: [a, b])
        #expect(result.map(\.id) == ["B"])
    }

    @Test func cornerResizeMovesBothBorders() {
        // A = top-left quarter, resized from its bottom-right corner; B right-top, C bottom-left.
        let old = CGRect(x: 0, y: 0, width: 500, height: 400)
        let b = window("B", 500, 0, 500, 400)
        let c = window("C", 0, 400, 500, 400)
        let result = resolve(old: old, new: CGRect(x: 0, y: 0, width: 560, height: 450), neighbours: [b, c])
        #expect(frame(of: "B", in: result) == CGRect(x: 560, y: 0, width: 440, height: 400))
        #expect(frame(of: "C", in: result) == CGRect(x: 0, y: 450, width: 500, height: 350))
    }
}

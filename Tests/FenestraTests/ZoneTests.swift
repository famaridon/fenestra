import CoreGraphics
import Testing
@testable import Fenestra

struct ZoneTests {
    let area = CGRect(x: 0, y: 0, width: 900, height: 600)

    @Test func halvesWithoutGap() {
        #expect(Zone.leftHalf.frame(in: area, gap: 0) == CGRect(x: 0, y: 0, width: 450, height: 600))
        #expect(Zone.rightHalf.frame(in: area, gap: 0) == CGRect(x: 450, y: 0, width: 450, height: 600))
        #expect(Zone.topHalf.frame(in: area, gap: 0) == CGRect(x: 0, y: 0, width: 900, height: 300))
        #expect(Zone.bottomHalf.frame(in: area, gap: 0) == CGRect(x: 0, y: 300, width: 900, height: 300))
        #expect(Zone.maximize.frame(in: area, gap: 0) == area)
    }

    @Test func quartersWithoutGap() {
        #expect(Zone.topLeft.frame(in: area, gap: 0) == CGRect(x: 0, y: 0, width: 450, height: 300))
        #expect(Zone.topRight.frame(in: area, gap: 0) == CGRect(x: 450, y: 0, width: 450, height: 300))
        #expect(Zone.bottomLeft.frame(in: area, gap: 0) == CGRect(x: 0, y: 300, width: 450, height: 300))
        #expect(Zone.bottomRight.frame(in: area, gap: 0) == CGRect(x: 450, y: 300, width: 450, height: 300))
    }

    @Test func thirdsWithoutGap() {
        #expect(Zone.leftThird.frame(in: area, gap: 0) == CGRect(x: 0, y: 0, width: 300, height: 600))
        #expect(Zone.centerThird.frame(in: area, gap: 0) == CGRect(x: 300, y: 0, width: 300, height: 600))
        #expect(Zone.rightThird.frame(in: area, gap: 0) == CGRect(x: 600, y: 0, width: 300, height: 600))
        #expect(Zone.leftTwoThirds.frame(in: area, gap: 0) == CGRect(x: 0, y: 0, width: 600, height: 600))
        #expect(Zone.rightTwoThirds.frame(in: area, gap: 0) == CGRect(x: 300, y: 0, width: 600, height: 600))
    }

    @Test func gapIsKeptBetweenWindowsAndWithScreenEdges() {
        let left = Zone.leftHalf.frame(in: area, gap: 10)
        let right = Zone.rightHalf.frame(in: area, gap: 10)
        #expect(left == CGRect(x: 10, y: 10, width: 435, height: 580))
        #expect(right == CGRect(x: 455, y: 10, width: 435, height: 580))
        #expect(right.minX - left.maxX == 10)
        #expect(Zone.maximize.frame(in: area, gap: 10) == CGRect(x: 10, y: 10, width: 880, height: 580))
    }

    @Test func gapBetweenQuarters() {
        let tl = Zone.topLeft.frame(in: area, gap: 10)
        let bl = Zone.bottomLeft.frame(in: area, gap: 10)
        let tr = Zone.topRight.frame(in: area, gap: 10)
        #expect(bl.minY - tl.maxY == 10)
        #expect(tr.minX - tl.maxX == 10)
    }

    @Test func complements() {
        #expect(Zone.leftHalf.complement == .rightHalf)
        #expect(Zone.rightHalf.complement == .leftHalf)
        #expect(Zone.topHalf.complement == .bottomHalf)
        #expect(Zone.bottomHalf.complement == .topHalf)
        #expect(Zone.topLeft.complement == .bottomLeft)
        #expect(Zone.bottomRight.complement == .topRight)
        #expect(Zone.maximize.complement == nil)
        #expect(Zone.leftThird.complement == nil)
    }

    @Test func overlaps() {
        #expect(Zone.rightHalf.overlaps(.rightHalf))
        #expect(Zone.rightHalf.overlaps(.topRight))
        #expect(Zone.bottomLeft.overlaps(.leftHalf))
        #expect(Zone.maximize.overlaps(.bottomRight))
        #expect(Zone.rightThird.overlaps(.rightHalf))
        #expect(!Zone.leftHalf.overlaps(.rightHalf))
        #expect(!Zone.topLeft.overlaps(.bottomLeft))
        #expect(!Zone.topLeft.overlaps(.bottomRight))
    }

    @Test func defaultEnabledExcludesThirds() {
        #expect(Zone.defaultEnabled.contains(.leftHalf))
        #expect(Zone.defaultEnabled.contains(.maximize))
        #expect(!Zone.defaultEnabled.contains(.centerThird))
    }
}

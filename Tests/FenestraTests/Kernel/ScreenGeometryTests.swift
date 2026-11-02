import CoreGraphics
import Testing
@testable import Fenestra

struct ScreenGeometryTests {
    let primaryHeight: CGFloat = 1080

    @Test func pointConversion() {
        #expect(ScreenGeometry.toAX(CGPoint(x: 100, y: 1080), primaryHeight: primaryHeight) == CGPoint(x: 100, y: 0))
        #expect(ScreenGeometry.toCocoa(CGPoint(x: 100, y: 0), primaryHeight: primaryHeight) == CGPoint(x: 100, y: 1080))
    }

    @Test func primaryRectConversion() {
        let cocoa = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        #expect(ScreenGeometry.toAX(cocoa, primaryHeight: primaryHeight) == CGRect(x: 0, y: 0, width: 1920, height: 1080))
    }

    @Test func portraitDisplayToTheRight() {
        // Cocoa: portrait display whose bottom is 240 pt below the primary's bottom (y up), so its top is at 1680.
        let cocoa = CGRect(x: 1920, y: -240, width: 1080, height: 1920)
        let ax = ScreenGeometry.toAX(cocoa, primaryHeight: primaryHeight)
        #expect(ax == CGRect(x: 1920, y: -600, width: 1080, height: 1920))
    }

    @Test func roundTripWithTwoDisplays() {
        let rects = [
            CGRect(x: 0, y: 0, width: 1920, height: 1080),
            CGRect(x: 1920, y: -240, width: 1080, height: 1920),
            CGRect(x: 2000, y: 300.5, width: 400, height: 250.25),
        ]
        for r in rects {
            let ax = ScreenGeometry.toAX(r, primaryHeight: primaryHeight)
            #expect(ScreenGeometry.toCocoa(ax, primaryHeight: primaryHeight) == r)
        }
        let p = CGPoint(x: 2500, y: -100)
        #expect(ScreenGeometry.toCocoa(ScreenGeometry.toAX(p, primaryHeight: primaryHeight), primaryHeight: primaryHeight) == p)
    }
}

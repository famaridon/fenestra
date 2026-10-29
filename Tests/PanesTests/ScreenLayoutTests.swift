import CoreGraphics
import Testing
@testable import Panes

struct ScreenLayoutTests {
    let primary = Fixtures.primary
    let portrait = Fixtures.portrait
    let layout = Fixtures.twoScreens

    private func screen(_ id: CGDirectDisplayID, _ frame: CGRect) -> ScreenInfo {
        ScreenInfo(id: id, frame: frame, visibleFrame: frame)
    }

    @Test func lookupById() {
        #expect(layout.screen(id: 2) == portrait)
        #expect(layout.screen(id: 99) == nil)
    }

    @Test func containingPoint() {
        #expect(layout.screen(containing: CGPoint(x: 10, y: 10)) == primary)
        #expect(layout.screen(containing: CGPoint(x: 2000, y: -400)) == portrait)
        #expect(layout.screen(containing: CGPoint(x: 5000, y: 0)) == nil)
    }

    @Test func screenForWindowByLargestIntersection() {
        // 700 pt on the primary, 300 on the portrait.
        #expect(layout.screen(for: CGRect(x: 1220, y: 100, width: 1000, height: 500)) == primary)
        // 300 on the primary, 700 on the portrait.
        #expect(layout.screen(for: CGRect(x: 1620, y: 100, width: 1000, height: 500)) == portrait)
    }

    @Test func screenForWindowOffEveryScreenIsClosest() {
        #expect(layout.screen(for: CGRect(x: 5000, y: 0, width: 100, height: 100)) == portrait)
        #expect(layout.screen(for: CGRect(x: -900, y: 2000, width: 100, height: 100)) == primary)
    }

    @Test func neighbors() {
        #expect(layout.neighbor(of: primary, toward: .right) == portrait)
        #expect(layout.neighbor(of: portrait, toward: .left) == primary)
        #expect(layout.neighbor(of: primary, toward: .left) == nil)
        #expect(layout.neighbor(of: primary, toward: .up) == nil)
        #expect(layout.neighbor(of: primary, toward: .down) == nil)
        #expect(layout.neighbor(of: portrait, toward: .right) == nil)
    }

    @Test func verticalNeighbors() {
        let above = screen(3, CGRect(x: 0, y: -1080, width: 1920, height: 1080))
        let l = ScreenLayout(screens: [primary, above])
        #expect(l.neighbor(of: primary, toward: .up) == above)
        #expect(l.neighbor(of: above, toward: .down) == primary)
        #expect(l.neighbor(of: primary, toward: .right) == nil)
    }

    @Test func neighborRequiresPerpendicularOverlap() {
        let far = screen(4, CGRect(x: 1920, y: 2000, width: 800, height: 600))
        #expect(ScreenLayout(screens: [primary, far]).neighbor(of: primary, toward: .right) == nil)
    }

    @Test func neighborPicksClosest() {
        let farther = screen(5, CGRect(x: 3000, y: 0, width: 800, height: 600))
        let l = ScreenLayout(screens: [primary, farther, portrait])
        #expect(l.neighbor(of: primary, toward: .right) == portrait)
    }

    @Test func nextAndPreviousFollowReadingOrderAndWrap() {
        let third = screen(6, CGRect(x: 3000, y: 0, width: 800, height: 600))
        // Deliberately unordered input.
        let l = ScreenLayout(screens: [third, primary, portrait])
        #expect(l.next(after: primary) == portrait)
        #expect(l.next(after: portrait) == third)
        #expect(l.next(after: third) == primary)
        #expect(l.previous(before: primary) == third)
        #expect(l.previous(before: third) == portrait)
    }

    @Test func singleScreenHasNoNextOrPrevious() {
        let l = ScreenLayout(screens: [primary])
        #expect(l.next(after: primary) == nil)
        #expect(l.previous(before: primary) == nil)
    }
}

import CoreGraphics
import Testing
@testable import Fenestra

struct KeyboardSnapResolverTests {
    let landscape = Fixtures.primary  // id 1
    let portrait = Fixtures.portrait  // id 2, to the right of the landscape one
    let resolver = KeyboardSnapResolver()

    /// A portrait screen stacked above `portrait` (id 3) and one below (id 4).
    var stacked: (above: ScreenInfo, below: ScreenInfo, layout: ScreenLayout) {
        let above = ScreenInfo(id: 3, frame: CGRect(x: 1920, y: -2340, width: 1080, height: 1920),
                               visibleFrame: CGRect(x: 1920, y: -2340, width: 1080, height: 1920))
        let below = ScreenInfo(id: 4, frame: CGRect(x: 1920, y: 1500, width: 1080, height: 1920),
                               visibleFrame: CGRect(x: 1920, y: 1500, width: 1080, height: 1920))
        return (above, below, ScreenLayout(screens: [landscape, portrait, above, below]))
    }

    /// Expected outcome, relative to the current screen unless `on` is given.
    enum Expect: Equatable {
        case place(Zone)
        case restore
        case none
    }

    private func run(_ action: SnapAction, _ zone: Zone?, on screen: ScreenInfo, layout: ScreenLayout) -> SnapCommand {
        let state = zone.map { WindowSnapState(zone: $0, screenID: screen.id) }
        return resolver.command(for: action, state: state, on: screen, layout: layout)
    }

    private func check(_ action: SnapAction, on screen: ScreenInfo, layout: ScreenLayout,
                       _ table: [(Zone?, Expect)], sourceLocation: SourceLocation = #_sourceLocation) {
        for (zone, expect) in table {
            let expected: SnapCommand = switch expect {
            case .place(let z): .place(z, on: screen)
            case .restore: .restore
            case .none: .none
            }
            let got = run(action, zone, on: screen, layout: layout)
            #expect(got == expected, "\(action) from \(String(describing: zone)) on screen \(screen.id)", sourceLocation: sourceLocation)
        }
    }

    // MARK: left / right

    @Test func leftOnSingleScreen() {
        let solo = ScreenLayout(screens: [landscape])
        check(.left, on: landscape, layout: solo, [
            (nil, .place(.leftHalf)),
            (.maximize, .place(.leftHalf)),
            (.topHalf, .place(.leftHalf)),
            (.bottomHalf, .place(.leftHalf)),
            (.leftThird, .place(.leftHalf)),
            (.centerThird, .place(.leftHalf)),
            (.rightTwoThirds, .place(.leftHalf)),
            (.rightHalf, .place(.leftHalf)),
            (.topRight, .place(.topLeft)),
            (.bottomRight, .place(.bottomLeft)),
            (.leftHalf, .restore),
            (.topLeft, .restore),
            (.bottomLeft, .restore),
        ])
    }

    @Test func rightOnSingleScreen() {
        let solo = ScreenLayout(screens: [landscape])
        check(.right, on: landscape, layout: solo, [
            (nil, .place(.rightHalf)),
            (.maximize, .place(.rightHalf)),
            (.topHalf, .place(.rightHalf)),
            (.bottomHalf, .place(.rightHalf)),
            (.rightThird, .place(.rightHalf)),
            (.leftHalf, .place(.rightHalf)),
            (.topLeft, .place(.topRight)),
            (.bottomLeft, .place(.bottomRight)),
            (.rightHalf, .restore),
            (.topRight, .restore),
            (.bottomRight, .restore),
        ])
    }

    @Test func rightHopsToNeighbourScreenWithMirrorZone() {
        let layout = Fixtures.twoScreens
        #expect(run(.right, .rightHalf, on: landscape, layout: layout) == .place(.leftHalf, on: portrait))
        #expect(run(.right, .topRight, on: landscape, layout: layout) == .place(.topLeft, on: portrait))
        #expect(run(.right, .bottomRight, on: landscape, layout: layout) == .place(.bottomLeft, on: portrait))
        // No screen to the right of the portrait one.
        #expect(run(.right, .rightHalf, on: portrait, layout: layout) == .restore)
    }

    @Test func leftHopsToNeighbourScreenWithMirrorZone() {
        let layout = Fixtures.twoScreens
        #expect(run(.left, .leftHalf, on: portrait, layout: layout) == .place(.rightHalf, on: landscape))
        #expect(run(.left, .topLeft, on: portrait, layout: layout) == .place(.topRight, on: landscape))
        #expect(run(.left, .bottomLeft, on: portrait, layout: layout) == .place(.bottomRight, on: landscape))
    }

    @Test func rightTwiceFromUnsnappedReachesRightScreen() {
        let layout = Fixtures.twoScreens
        #expect(run(.right, nil, on: landscape, layout: layout) == .place(.rightHalf, on: landscape))
        #expect(run(.right, .rightHalf, on: landscape, layout: layout) == .place(.leftHalf, on: portrait))
    }

    @Test func leftRightWorkOnPortraitToo() {
        let solo = ScreenLayout(screens: [portrait])
        check(.left, on: portrait, layout: solo, [
            (nil, .place(.leftHalf)),
            (.topHalf, .place(.leftHalf)),
            (.rightHalf, .place(.leftHalf)),
            (.bottomRight, .place(.bottomLeft)),
            (.leftHalf, .restore),
        ])
        check(.right, on: portrait, layout: solo, [
            (nil, .place(.rightHalf)),
            (.bottomHalf, .place(.rightHalf)),
            (.topLeft, .place(.topRight)),
            (.rightHalf, .restore),
        ])
    }

    // MARK: up / down, landscape

    @Test func upLandscape() {
        let layout = Fixtures.twoScreens
        check(.up, on: landscape, layout: layout, [
            (nil, .place(.maximize)),
            (.topHalf, .place(.maximize)),
            (.bottomHalf, .place(.maximize)),
            (.leftThird, .place(.maximize)),
            (.rightTwoThirds, .place(.maximize)),
            (.leftHalf, .place(.topLeft)),
            (.rightHalf, .place(.topRight)),
            (.bottomLeft, .place(.leftHalf)),
            (.bottomRight, .place(.rightHalf)),
            (.maximize, .none),
            (.topLeft, .none),
            (.topRight, .none),
        ])
    }

    @Test func downLandscape() {
        let layout = Fixtures.twoScreens
        check(.down, on: landscape, layout: layout, [
            (nil, .none),
            (.maximize, .restore),
            (.bottomLeft, .restore),
            (.bottomRight, .restore),
            (.topHalf, .restore),
            (.bottomHalf, .restore),
            (.centerThird, .restore),
            (.leftHalf, .place(.bottomLeft)),
            (.rightHalf, .place(.bottomRight)),
            (.topLeft, .place(.leftHalf)),
            (.topRight, .place(.rightHalf)),
        ])
    }

    // MARK: up / down, portrait

    @Test func upPortraitWithoutNeighbour() {
        let layout = Fixtures.twoScreens
        check(.up, on: portrait, layout: layout, [
            (nil, .place(.topHalf)),
            (.leftThird, .place(.topHalf)),
            (.topHalf, .place(.maximize)),
            (.bottomHalf, .place(.topHalf)),
            (.leftHalf, .place(.topLeft)),
            (.rightHalf, .place(.topRight)),
            (.bottomLeft, .place(.leftHalf)),
            (.bottomRight, .place(.rightHalf)),
            (.maximize, .none),
            (.topLeft, .none),
            (.topRight, .none),
        ])
    }

    @Test func downPortraitWithoutNeighbour() {
        let layout = Fixtures.twoScreens
        check(.down, on: portrait, layout: layout, [
            (nil, .place(.bottomHalf)),
            (.rightThird, .place(.bottomHalf)),
            (.maximize, .restore),
            (.topHalf, .place(.bottomHalf)),
            (.bottomHalf, .restore),
            (.leftHalf, .place(.bottomLeft)),
            (.rightHalf, .place(.bottomRight)),
            (.topLeft, .place(.leftHalf)),
            (.topRight, .place(.rightHalf)),
            (.bottomLeft, .restore),
            (.bottomRight, .restore),
        ])
    }

    @Test func upPortraitFromBottomHalfHopsToScreenAbove() {
        let s = stacked
        #expect(run(.up, .bottomHalf, on: portrait, layout: s.layout) == .place(.bottomHalf, on: s.above))
    }

    @Test func downPortraitFromTopHalfHopsToScreenBelow() {
        let s = stacked
        #expect(run(.down, .topHalf, on: portrait, layout: s.layout) == .place(.topHalf, on: s.below))
    }

    // MARK: direct placement

    @Test func directZones() {
        let layout = Fixtures.twoScreens
        let pairs: [(SnapAction, Zone)] = [
            (.topLeft, .topLeft), (.topRight, .topRight), (.bottomLeft, .bottomLeft),
            (.bottomRight, .bottomRight), (.maximize, .maximize),
            (.leftThird, .leftThird), (.centerThird, .centerThird), (.rightThird, .rightThird),
            (.leftTwoThirds, .leftTwoThirds), (.rightTwoThirds, .rightTwoThirds),
        ]
        for screen in [landscape, portrait] {
            for (action, zone) in pairs {
                #expect(run(action, nil, on: screen, layout: layout) == .place(zone, on: screen))
                #expect(run(action, .leftHalf, on: screen, layout: layout) == .place(zone, on: screen))
                #expect(run(action, zone, on: screen, layout: layout) == .none)
            }
        }
    }

    // MARK: restore

    @Test func restore() {
        let layout = Fixtures.twoScreens
        #expect(run(.restore, nil, on: landscape, layout: layout) == .none)
        #expect(run(.restore, .leftHalf, on: landscape, layout: layout) == .restore)
        #expect(run(.restore, .maximize, on: portrait, layout: layout) == .restore)
    }

    // MARK: displays

    @Test func nextAndPreviousDisplayKeepTheZone() {
        let layout = Fixtures.twoScreens
        #expect(run(.nextDisplay, .leftHalf, on: landscape, layout: layout) == .place(.leftHalf, on: portrait))
        #expect(run(.nextDisplay, .topRight, on: portrait, layout: layout) == .place(.topRight, on: landscape))  // wraps
        #expect(run(.previousDisplay, .maximize, on: portrait, layout: layout) == .place(.maximize, on: landscape))
        #expect(run(.previousDisplay, .bottomHalf, on: landscape, layout: layout) == .place(.bottomHalf, on: portrait))  // wraps
    }

    @Test func nextAndPreviousDisplayWithoutOtherScreenOrSnap() {
        let solo = ScreenLayout(screens: [landscape])
        #expect(run(.nextDisplay, .leftHalf, on: landscape, layout: solo) == .none)
        #expect(run(.previousDisplay, .leftHalf, on: landscape, layout: solo) == .none)
        let layout = Fixtures.twoScreens
        #expect(run(.nextDisplay, nil, on: landscape, layout: layout) == .none)
        #expect(run(.previousDisplay, nil, on: landscape, layout: layout) == .none)
    }

    // MARK: state on another screen

    @Test func stateFromAnotherScreenIsTreatedAsNotSnapped() {
        let layout = Fixtures.twoScreens
        let stale = WindowSnapState(zone: .leftHalf, screenID: portrait.id)
        // Would be "restore" if the state applied (leftHalf + left, no neighbour left of landscape).
        #expect(resolver.command(for: .left, state: stale, on: landscape, layout: layout) == .place(.leftHalf, on: landscape))
        #expect(resolver.command(for: .down, state: stale, on: landscape, layout: layout) == .none)
        #expect(resolver.command(for: .restore, state: stale, on: landscape, layout: layout) == .none)
        #expect(resolver.command(for: .nextDisplay, state: stale, on: landscape, layout: layout) == .none)
        // A direct placement on the same zone number but another screen still places.
        let staleTopLeft = WindowSnapState(zone: .topLeft, screenID: portrait.id)
        #expect(resolver.command(for: .topLeft, state: staleTopLeft, on: landscape, layout: layout) == .place(.topLeft, on: landscape))
    }
}

import Testing
@testable import Fenestra

struct SnapLayoutTests {
    @Test func landscapeDefaultsHideThirds() {
        let layouts = SnapLayout.available(for: .landscape, enabledZones: Zone.defaultEnabled)
        #expect(layouts.map(\.zones) == [
            [.leftHalf, .rightHalf],
            [.leftHalf, .topRight, .bottomRight],
            [.topLeft, .bottomLeft, .rightHalf],
            [.topLeft, .topRight, .bottomLeft, .bottomRight],
            [.maximize],
        ])
    }

    @Test func landscapeWithEveryZone() {
        let layouts = SnapLayout.available(for: .landscape, enabledZones: Set(Zone.allCases))
        #expect(layouts.count == 8)
        #expect(layouts.contains { $0.zones == [.leftTwoThirds, .rightThird] })
    }

    @Test func portraitSplitsTopAndBottom() {
        let layouts = SnapLayout.available(for: .portrait, enabledZones: Set(Zone.allCases))
        #expect(layouts.first?.zones == [.topHalf, .bottomHalf])
        #expect(!layouts.contains { $0.zones.contains(where: \.isThird) })
    }

    @Test func layoutWithADisabledZoneIsHidden() {
        var zones = Zone.defaultEnabled
        zones.remove(.topRight)
        let layouts = SnapLayout.available(for: .landscape, enabledZones: zones)
        #expect(!layouts.contains { $0.zones.contains(.topRight) })
        #expect(layouts.contains { $0.zones == [.leftHalf, .rightHalf] })
    }

    @Test func zonesOfALayoutDoNotOverlap() {
        for layout in SnapLayout.available(for: .landscape, enabledZones: Set(Zone.allCases))
            + SnapLayout.available(for: .portrait, enabledZones: Set(Zone.allCases)) {
            for (i, a) in layout.zones.enumerated() {
                for b in layout.zones[(i + 1)...] {
                    #expect(!a.overlaps(b), "\(layout.id)")
                }
            }
        }
    }
}

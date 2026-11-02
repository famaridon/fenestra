import CoreGraphics
import Testing
@testable import Fenestra

struct DragZoneResolverTests {
    let landscape = Fixtures.primary   // 0,0 1920x1080
    let portrait = Fixtures.portrait   // x 1920..3000, y -420..1500
    let resolver = DragZoneResolver(config: .init())

    private func zone(_ x: CGFloat, _ y: CGFloat, on s: ScreenInfo, _ r: DragZoneResolver? = nil) -> Zone? {
        (r ?? resolver).zone(forPointer: CGPoint(x: x, y: y), on: s)
    }

    @Test func landscapeEdges() {
        #expect(zone(0, 540, on: landscape) == .leftHalf)
        #expect(zone(1919, 540, on: landscape) == .rightHalf)
        #expect(zone(960, 0, on: landscape) == .maximize)
        #expect(zone(960, 1079, on: landscape) == nil)
        #expect(zone(960, 540, on: landscape) == nil)
    }

    @Test func thresholdBoundaries() {
        #expect(zone(2, 540, on: landscape) == .leftHalf)
        #expect(zone(3, 540, on: landscape) == nil)
        #expect(zone(1918, 540, on: landscape) == .rightHalf)
        #expect(zone(1917, 540, on: landscape) == nil)
        var r = resolver
        r.config.edgeThreshold = 10
        #expect(zone(10, 540, on: landscape, r) == .leftHalf)
        #expect(zone(11, 540, on: landscape, r) == nil)
    }

    @Test func pointerOutsideFrameStillCounts() {
        #expect(zone(-5, 540, on: landscape) == .leftHalf)
        #expect(zone(1930, 540, on: landscape) == .rightHalf)
        #expect(zone(960, -3, on: landscape) == .maximize)
        #expect(zone(-5, -5, on: landscape) == .topLeft)
    }

    @Test func landscapeCorners() {
        #expect(zone(0, 0, on: landscape) == .topLeft)
        #expect(zone(0, 120, on: landscape) == .topLeft)
        #expect(zone(120, 0, on: landscape) == .topLeft)
        #expect(zone(1919, 0, on: landscape) == .topRight)
        #expect(zone(1800, 0, on: landscape) == .topRight)
        #expect(zone(0, 1079, on: landscape) == .bottomLeft)
        #expect(zone(0, 960, on: landscape) == .bottomLeft)
        #expect(zone(1919, 1079, on: landscape) == .bottomRight)
        #expect(zone(1919, 960, on: landscape) == .bottomRight)
        // Bottom edge near a corner is a corner even on landscape.
        #expect(zone(100, 1079, on: landscape) == .bottomLeft)
    }

    @Test func justBeyondCornerLengthIsPlainEdge() {
        #expect(zone(0, 121, on: landscape) == .leftHalf)
        #expect(zone(121, 0, on: landscape) == .maximize)
        #expect(zone(1919, 958, on: landscape) == .rightHalf)
    }

    @Test func customCornerLength() {
        var r = resolver
        r.config.cornerLength = 40
        #expect(zone(0, 40, on: landscape, r) == .topLeft)
        #expect(zone(0, 41, on: landscape, r) == .leftHalf)
    }

    @Test func portraitEdges() {
        #expect(zone(1920, 540, on: portrait) == .leftHalf)
        #expect(zone(2999, 540, on: portrait) == .rightHalf)
        #expect(zone(2400, -420, on: portrait) == .topHalf)
        #expect(zone(2400, 1499, on: portrait) == .bottomHalf)
        #expect(zone(2400, 540, on: portrait) == nil)
    }

    @Test func portraitTopEdgeMaximizes() {
        var r = resolver
        r.config.portraitTopEdgeMaximizes = true
        #expect(zone(2400, -420, on: portrait, r) == .maximize)
        // Bottom edge unaffected.
        #expect(zone(2400, 1499, on: portrait, r) == .bottomHalf)
    }

    @Test func portraitSideEdgesDisabled() {
        var r = resolver
        r.config.portraitSideEdgesEnabled = false
        #expect(zone(1920, 540, on: portrait, r) == nil)
        #expect(zone(2999, 540, on: portrait, r) == nil)
        #expect(zone(2400, -420, on: portrait, r) == .topHalf)
        // Landscape screens keep their side edges.
        #expect(zone(0, 540, on: landscape, r) == .leftHalf)
    }

    @Test func portraitCorners() {
        #expect(zone(1920, -420, on: portrait) == .topLeft)
        #expect(zone(2999, 1499, on: portrait) == .bottomRight)
        #expect(zone(2900, 1499, on: portrait) == .bottomRight)
        #expect(zone(1920, 1400, on: portrait) == .bottomLeft)
    }

    @Test func disabledZonesGiveNilWithoutFallback() {
        var r = resolver
        r.config.enabledZones.remove(.leftHalf)
        #expect(zone(0, 540, on: landscape, r) == nil)
        #expect(zone(1919, 540, on: landscape, r) == .rightHalf)

        r.config.enabledZones.remove(.topLeft)
        #expect(zone(0, 0, on: landscape, r) == nil)

        r.config.enabledZones.remove(.maximize)
        #expect(zone(960, 0, on: landscape, r) == nil)

        r.config.enabledZones.remove(.topHalf)
        #expect(zone(2400, -420, on: portrait, r) == nil)
    }

    @Test func thirdsAreNeverProducedByDragging() {
        var r = resolver
        r.config.enabledZones = Set(Zone.allCases)
        for (x, y) in [(0.0, 540.0), (1919.0, 540.0), (960.0, 0.0), (0.0, 0.0)] {
            #expect(zone(x, y, on: landscape, r)?.isThird == false)
        }
    }
}

extension DragZoneResolverTests {
    /// The junction between two displays uses the wider band, outer edges keep the tight one.
    @Test func innerEdgesUseWiderBand() {
        let inner: Set<Direction> = [.right]
        // 20 pt from the shared right edge: inside the 24 pt inner band.
        #expect(resolver.zone(forPointer: CGPoint(x: 1900, y: 540), on: landscape, innerEdges: inner) == .rightHalf)
        // Same distance from the outer left edge: nothing.
        #expect(resolver.zone(forPointer: CGPoint(x: 20, y: 540), on: landscape, innerEdges: inner) == nil)
        // Beyond the inner band: nothing.
        #expect(resolver.zone(forPointer: CGPoint(x: 1895, y: 540), on: landscape, innerEdges: inner) == nil)
        // Corners along the inner edge follow the same band.
        #expect(resolver.zone(forPointer: CGPoint(x: 1900, y: 50), on: landscape, innerEdges: inner) == .topRight)
        // Without the inner-edge information the tight threshold applies.
        #expect(resolver.zone(forPointer: CGPoint(x: 1900, y: 540), on: landscape) == nil)
    }

    @Test func innerBandIsConfigurable() {
        var r = resolver
        r.config.innerEdgeThreshold = 60
        #expect(r.zone(forPointer: CGPoint(x: 1861, y: 540), on: landscape, innerEdges: [.right]) == .rightHalf)
        #expect(r.zone(forPointer: CGPoint(x: 1859, y: 540), on: landscape, innerEdges: [.right]) == nil)
    }
}

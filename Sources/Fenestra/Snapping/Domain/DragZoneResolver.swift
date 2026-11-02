import CoreGraphics
import Foundation

/// Maps the pointer position, while dragging a window, to the zone it triggers.
struct DragZoneResolver: Sendable {
    struct Config: Sendable, Equatable {
        /// Distance to an outer screen edge (points) that counts as "touching" it. The pointer
        /// stops on outer edges, so a tiny value is enough.
        var edgeThreshold: CGFloat = 2
        /// Width of the trigger band along an edge shared with another display. The pointer
        /// crosses such edges freely, so the band has to be wider to be reachable.
        var innerEdgeThreshold: CGFloat = 24
        /// Length of edge counted as a corner.
        var cornerLength: CGFloat = 120
        /// Portrait screens: the top edge maximizes instead of giving the top half.
        var portraitTopEdgeMaximizes = false
        /// Portrait screens: left and right edges are active.
        var portraitSideEdgesEnabled = true
        var enabledZones: Set<Zone> = Zone.defaultEnabled
    }

    var config: Config

    /// `pointer` and `screen.frame` are in AX coordinates. A pointer slightly outside the frame
    /// still counts as touching the nearest edge. A zone missing from `enabledZones` gives nil
    /// (no fallback to another zone). `innerEdges` lists the edges of `screen` that touch another
    /// display (see `ScreenLayout.innerEdges(of:)`): they use the wider `innerEdgeThreshold`.
    func zone(forPointer pointer: CGPoint, on screen: ScreenInfo, innerEdges: Set<Direction> = []) -> Zone? {
        let f = screen.frame
        let c = config.cornerLength
        func threshold(_ edge: Direction) -> CGFloat {
            innerEdges.contains(edge) ? config.innerEdgeThreshold : config.edgeThreshold
        }

        let nearLeft = pointer.x <= f.minX + threshold(.left)
        let nearRight = pointer.x >= f.maxX - threshold(.right)
        let nearTop = pointer.y <= f.minY + threshold(.up)
        let nearBottom = pointer.y >= f.maxY - threshold(.down)
        guard nearLeft || nearRight || nearTop || nearBottom else { return nil }

        let inLeft = pointer.x <= f.minX + c
        let inRight = pointer.x >= f.maxX - c
        let inTop = pointer.y <= f.minY + c
        let inBottom = pointer.y >= f.maxY - c

        // Corners first: touching one edge while close to a perpendicular one.
        let corner: Zone?
        if (nearLeft && inTop) || (nearTop && inLeft) {
            corner = .topLeft
        } else if (nearRight && inTop) || (nearTop && inRight) {
            corner = .topRight
        } else if (nearLeft && inBottom) || (nearBottom && inLeft) {
            corner = .bottomLeft
        } else if (nearRight && inBottom) || (nearBottom && inRight) {
            corner = .bottomRight
        } else {
            corner = nil
        }
        if let corner { return enabled(corner) }

        // Plain edges.
        let portrait = screen.orientation == .portrait
        if nearLeft || nearRight {
            guard !portrait || config.portraitSideEdgesEnabled else { return nil }
            return enabled(nearLeft ? .leftHalf : .rightHalf)
        }
        if nearTop {
            return enabled(portrait && !config.portraitTopEdgeMaximizes ? .topHalf : .maximize)
        }
        // Bottom edge: only meaningful on portrait screens.
        return portrait ? enabled(.bottomHalf) : nil
    }

    private func enabled(_ zone: Zone) -> Zone? {
        config.enabledZones.contains(zone) ? zone : nil
    }
}

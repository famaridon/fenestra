import CoreGraphics
import Foundation

/// Maps the pointer position, while dragging a window, to the zone it triggers.
struct DragZoneResolver: Sendable {
    struct Config: Sendable, Equatable {
        /// Distance to a screen edge (points) that counts as "touching" it.
        var edgeThreshold: CGFloat = 2
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
    /// (no fallback to another zone).
    func zone(forPointer pointer: CGPoint, on screen: ScreenInfo) -> Zone? {
        let f = screen.frame
        let t = config.edgeThreshold
        let c = config.cornerLength

        let nearLeft = pointer.x <= f.minX + t
        let nearRight = pointer.x >= f.maxX - t
        let nearTop = pointer.y <= f.minY + t
        let nearBottom = pointer.y >= f.maxY - t
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

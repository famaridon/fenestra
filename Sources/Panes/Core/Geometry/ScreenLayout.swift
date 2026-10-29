import CoreGraphics
import Foundation

/// The set of connected displays, in AX coordinates, with neighbourhood queries.
struct ScreenLayout: Sendable {
    let screens: [ScreenInfo]

    init(screens: [ScreenInfo]) {
        self.screens = screens
    }

    func screen(id: CGDirectDisplayID) -> ScreenInfo? {
        screens.first { $0.id == id }
    }

    func screen(containing point: CGPoint) -> ScreenInfo? {
        screens.first { $0.frame.contains(point) }
    }

    /// The screen holding the largest part of `windowFrame`; the closest one if it is off every screen.
    func screen(for windowFrame: CGRect) -> ScreenInfo? {
        var best: (screen: ScreenInfo, area: CGFloat)?
        for screen in screens {
            let inter = screen.frame.intersection(windowFrame)
            let area = inter.isNull ? 0 : inter.width * inter.height
            if area > (best?.area ?? 0) { best = (screen, area) }
        }
        if let best { return best.screen }
        let center = CGPoint(x: windowFrame.midX, y: windowFrame.midY)
        return screens.min { distance(from: center, to: $0.frame) < distance(from: center, to: $1.frame) }
    }

    /// Neighbouring screen in a direction: it must lie on that side, overlap `screen` on the
    /// perpendicular axis, and is the closest such screen (ties: the largest overlap).
    func neighbor(of screen: ScreenInfo, toward direction: Direction) -> ScreenInfo? {
        let f = screen.frame
        let slack: CGFloat = 1  // displays that touch may be off by a rounding error
        var best: (screen: ScreenInfo, gap: CGFloat, overlap: CGFloat)?
        for other in screens where other.id != screen.id {
            let o = other.frame
            let gap: CGFloat
            let overlap: CGFloat
            switch direction {
            case .right:
                gap = o.minX - f.maxX
                overlap = min(f.maxY, o.maxY) - max(f.minY, o.minY)
            case .left:
                gap = f.minX - o.maxX
                overlap = min(f.maxY, o.maxY) - max(f.minY, o.minY)
            case .down:
                gap = o.minY - f.maxY
                overlap = min(f.maxX, o.maxX) - max(f.minX, o.minX)
            case .up:
                gap = f.minY - o.maxY
                overlap = min(f.maxX, o.maxX) - max(f.minX, o.minX)
            }
            guard gap >= -slack, overlap > 0 else { continue }
            if let b = best, b.gap < gap || (b.gap == gap && b.overlap >= overlap) { continue }
            best = (other, gap, overlap)
        }
        return best?.screen
    }

    /// Edges of `screen` that touch another display. The pointer crosses them instead of stopping.
    func innerEdges(of screen: ScreenInfo) -> Set<Direction> {
        var edges: Set<Direction> = []
        for direction in [Direction.left, .right, .up, .down] where neighbor(of: screen, toward: direction) != nil {
            edges.insert(direction)
        }
        return edges
    }

    /// Next screen in reading order (minX, then minY), wrapping around. nil with a single screen.
    func next(after screen: ScreenInfo) -> ScreenInfo? {
        step(from: screen, by: 1)
    }

    func previous(before screen: ScreenInfo) -> ScreenInfo? {
        step(from: screen, by: -1)
    }

    private func step(from screen: ScreenInfo, by offset: Int) -> ScreenInfo? {
        guard screens.count > 1 else { return nil }
        let ordered = screens.sorted {
            ($0.frame.minX, $0.frame.minY) < ($1.frame.minX, $1.frame.minY)
        }
        guard let index = ordered.firstIndex(where: { $0.id == screen.id }) else { return nil }
        return ordered[(index + offset + ordered.count) % ordered.count]
    }

    /// Distance from a point to a rectangle (0 when inside).
    private func distance(from p: CGPoint, to r: CGRect) -> CGFloat {
        let dx = max(r.minX - p.x, 0, p.x - r.maxX)
        let dy = max(r.minY - p.y, 0, p.y - r.maxY)
        return (dx * dx + dy * dy).squareRoot()
    }
}

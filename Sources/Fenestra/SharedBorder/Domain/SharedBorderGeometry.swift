import CoreGraphics

/// Frame helpers of the shared border (pure). AX coordinates.
enum SharedBorderGeometry {
    /// `frame` with the edges that sat on an edge of the resized window (`old` -> `new`) moved by the
    /// same delta, as if dragged too; nil if no edge moved.
    static func shifted(_ frame: CGRect, old: CGRect, new: CGRect, tolerance: CGFloat) -> CGRect? {
        func edge(_ value: CGFloat, _ oldEdge: CGFloat, _ newEdge: CGFloat) -> CGFloat {
            abs(value - oldEdge) <= tolerance ? value + (newEdge - oldEdge) : value
        }
        let minX = edge(frame.minX, old.minX, new.minX), maxX = edge(frame.maxX, old.maxX, new.maxX)
        let minY = edge(frame.minY, old.minY, new.minY), maxY = edge(frame.maxY, old.maxY, new.maxY)
        let result = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        return result == frame ? nil : result
    }

    /// Moves the edge of `frame` that touched the `requested` neighbour frame onto the neighbour's
    /// `actual` edge (the neighbour refused part of the resize, e.g. a minimum size).
    static func corrected(_ frame: CGRect, requested: CGRect, actual: CGRect, gap: CGFloat) -> CGRect {
        var minX = frame.minX, maxX = frame.maxX, minY = frame.minY, maxY = frame.maxY
        if abs(maxX + gap - requested.minX) <= 1 { maxX = actual.minX - gap }
        if abs(minX - gap - requested.maxX) <= 1 { minX = actual.maxX + gap }
        if abs(maxY + gap - requested.minY) <= 1 { maxY = actual.minY - gap }
        if abs(minY - gap - requested.maxY) <= 1 { minY = actual.maxY + gap }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// True if both frames match within one point.
    static func close(_ a: CGRect, _ b: CGRect) -> Bool {
        abs(a.minX - b.minX) <= 1 && abs(a.minY - b.minY) <= 1
            && abs(a.width - b.width) <= 1 && abs(a.height - b.height) <= 1
    }
}

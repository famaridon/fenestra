import CoreGraphics

/// Frame computations of unsnapping and moving between displays (pure). AX coordinates.
enum SnapGeometry {
    /// Frame of a window given back its pre-snap `size` while dragged: the pointer keeps the same
    /// horizontal ratio in the window, and stays at most 30 points below its top edge.
    static func unsnappedFrame(restoring size: CGSize, from frame: CGRect, pointer: CGPoint) -> CGRect {
        let ratio = frame.width > 0 ? min(max((pointer.x - frame.minX) / frame.width, 0), 1) : 0.5
        let offsetY = min(max(pointer.y - frame.minY, 0), 30)
        return CGRect(origin: CGPoint(x: pointer.x - ratio * size.width, y: pointer.y - offsetY), size: size)
    }

    /// `frame` moved from the `source` area to the `target` area at the same relative position,
    /// shrunk to fit and kept inside the target.
    static func proportionalFrame(_ frame: CGRect, from source: CGRect, to target: CGRect) -> CGRect {
        let width = min(frame.width, target.width), height = min(frame.height, target.height)
        let relX = source.width > 0 ? (frame.minX - source.minX) / source.width : 0
        let relY = source.height > 0 ? (frame.minY - source.minY) / source.height : 0
        let x = min(max(target.minX + relX * target.width, target.minX), target.maxX - width)
        let y = min(max(target.minY + relY * target.height, target.minY), target.maxY - height)
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

import CoreGraphics
import Foundation

/// A window that may share a border with the one being resized.
struct BorderWindow<Key: Hashable & Sendable>: Sendable, Identifiable {
    var id: Key
    var frame: CGRect
    /// Minimum size of the window; (0, 0) when unknown.
    var minSize: CGSize
}

/// A new frame to apply to a window.
struct BorderAdjustment<Key: Hashable & Sendable>: Sendable, Equatable {
    var id: Key
    var frame: CGRect
}

/// Computes how windows glued to a resized window must follow it (F5).
enum SharedBorderResolver {
    /// A change smaller than this (points) is ignored.
    private static let epsilon: CGFloat = 0.5

    /// A snapped window went from `oldFrame` to `newFrame` (user resize). For every edge that moved,
    /// the neighbours whose opposite edge sat on the old edge position (within `tolerance`) and that
    /// overlap the window on the perpendicular axis are "attached": their opposite edge follows the
    /// new position, their far edge stays put. Minimum sizes are respected: if the border cannot go
    /// as far as requested it is clamped, the clamped position is applied to every attached
    /// neighbour, and the changed window gets an adjustment pulling it back to that position.
    /// Only frames that really change (> 0.5 pt) are returned. Pure, no side effects.
    static func adjustments<Key>(changed: Key, oldFrame: CGRect, newFrame: CGRect,
                                 neighbours: [BorderWindow<Key>], minSizeOfChanged: CGSize,
                                 tolerance: CGFloat) -> [BorderAdjustment<Key>] {
        let others = neighbours.filter { $0.id != changed }
        var state = State(
            old: oldFrame,
            changed: newFrame,
            minChanged: minSizeOfChanged,
            originals: others.map(\.frame),
            frames: others.map(\.frame),
            minSizes: others.map(\.minSize)
        )

        // Horizontal borders are handled by the same code as vertical ones on the transposed
        // geometry (x and y swapped): resolve minX/maxX, transpose, resolve again, transpose back.
        resolveVerticalBorders(&state, tolerance: tolerance)
        state = state.transposed()
        resolveVerticalBorders(&state, tolerance: tolerance)
        state = state.transposed()

        var result: [BorderAdjustment<Key>] = []
        if differs(state.changed, newFrame) {
            result.append(BorderAdjustment(id: changed, frame: state.changed))
        }
        for (index, window) in others.enumerated() where differs(state.frames[index], window.frame) {
            result.append(BorderAdjustment(id: window.id, frame: state.frames[index]))
        }
        return result
    }

    // MARK: - Internals

    /// Working data. `originals` are used to decide attachment, `frames` accumulate the results.
    private struct State {
        var old: CGRect
        var changed: CGRect
        var minChanged: CGSize
        var originals: [CGRect]
        var frames: [CGRect]
        var minSizes: [CGSize]

        func transposed() -> State {
            State(old: old.transposed, changed: changed.transposed, minChanged: minChanged.transposed,
                  originals: originals.map(\.transposed), frames: frames.map(\.transposed),
                  minSizes: minSizes.map(\.transposed))
        }
    }

    private static func differs(_ a: CGRect, _ b: CGRect) -> Bool {
        abs(a.minX - b.minX) > epsilon || abs(a.minY - b.minY) > epsilon
            || abs(a.maxX - b.maxX) > epsilon || abs(a.maxY - b.maxY) > epsilon
    }

    /// Handles the changed window's left and right edges (the borders that are vertical lines).
    private static func resolveVerticalBorders(_ s: inout State, tolerance: CGFloat) {
        // Right edge moved: neighbours on the right have their minX on the old maxX.
        if abs(s.changed.maxX - s.old.maxX) > epsilon {
            let attached = attachedIndices(s, tolerance: tolerance) { s.originals[$0].minX - s.old.maxX }
            if !attached.isEmpty {
                // Neighbours cannot start beyond (their maxX - min width); the changed window
                // cannot be narrower than its own minimum.
                let upper = attached.map { s.originals[$0].maxX - s.minSizes[$0].width }.min()!
                let lower = s.changed.minX + s.minChanged.width
                let x = min(max(s.changed.maxX, lower), upper)
                s.changed = rect(minX: s.changed.minX, maxX: x, like: s.changed)
                for i in attached { s.frames[i] = rect(minX: x, maxX: s.frames[i].maxX, like: s.frames[i]) }
            }
        }
        // Left edge moved: neighbours on the left have their maxX on the old minX.
        if abs(s.changed.minX - s.old.minX) > epsilon {
            let attached = attachedIndices(s, tolerance: tolerance) { s.originals[$0].maxX - s.old.minX }
            if !attached.isEmpty {
                let lower = attached.map { s.originals[$0].minX + s.minSizes[$0].width }.max()!
                let upper = s.changed.maxX - s.minChanged.width
                let x = max(min(s.changed.minX, upper), lower)
                s.changed = rect(minX: x, maxX: s.changed.maxX, like: s.changed)
                for i in attached { s.frames[i] = rect(minX: s.frames[i].minX, maxX: x, like: s.frames[i]) }
            }
        }
    }

    /// Neighbours whose facing edge is within tolerance of the old border (`offset` gives the
    /// distance) and whose y range overlaps the changed window's old y range.
    private static func attachedIndices(_ s: State, tolerance: CGFloat, offset: (Int) -> CGFloat) -> [Int] {
        s.originals.indices.filter { i in
            let o = s.originals[i]
            let overlap = min(o.maxY, s.old.maxY) - max(o.minY, s.old.minY)
            return abs(offset(i)) <= tolerance && overlap > tolerance
        }
    }

    /// `like` with its horizontal extent replaced.
    private static func rect(minX: CGFloat, maxX: CGFloat, like r: CGRect) -> CGRect {
        CGRect(x: minX, y: r.minY, width: maxX - minX, height: r.height)
    }
}

private extension CGRect {
    var transposed: CGRect { CGRect(x: minY, y: minX, width: height, height: width) }
}

private extension CGSize {
    var transposed: CGSize { CGSize(width: height, height: width) }
}

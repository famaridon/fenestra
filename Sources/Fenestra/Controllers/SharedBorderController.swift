import CoreGraphics

/// F5: propagates a resize of a snapped window to the snapped windows sharing its border.
@MainActor
final class SharedBorderController {
    private static let tolerance: CGFloat = 4
    private unowned let snapController: SnapController

    init(snapController: SnapController) {
        self.snapController = snapController
    }

    func windowResized(_ window: AXWindow, from old: CGRect, to new: CGRect) {
        guard let screenID = snapController.registry.record(for: window)?.screenID else { return }
        var frames: [AXWindow: CGRect] = [:]
        for (other, record) in snapController.snappedWindows(on: screenID, excluding: window) {
            frames[other] = record.snappedFrame
        }
        // Windows whose same-side edge sat on the moved edge follow it, as if dragged too.
        var pairs: [(AXWindow, CGRect, CGRect)] = [(window, old, new)]
        for (other, frame) in frames {
            if let moved = shifted(frame, old: old, new: new) { pairs.append((other, frame, moved)) }
        }
        let neighbours = frames.map { BorderWindow(id: $0.key, frame: $0.value, minSize: .zero) }
        for (key, from, to) in pairs {
            let others = neighbours.filter { $0.id != key }
            let adjustments = SharedBorderResolver.adjustments(
                changed: key, oldFrame: from, newFrame: to,
                neighbours: others, minSizeOfChanged: .zero, tolerance: Self.tolerance)
            if key != window { apply(key, to) }
            for adjustment in adjustments {
                let actual = apply(adjustment.id, adjustment.frame)
                if adjustment.id != key, !close(actual, adjustment.frame) {
                    // The app refused (minimum size): pull the changed window back onto the real edge (NF3).
                    apply(key, corrected(to, requested: adjustment.frame, actual: actual))
                }
            }
        }
    }

    /// Stores the final frame of the resized window at the end of the gesture.
    func finishResize(_ window: AXWindow) {
        if let frame = window.frame { snapController.updateSnappedFrame(window, to: frame) }
    }

    /// Sets the frame, records what the window actually got, and returns it.
    @discardableResult
    private func apply(_ window: AXWindow, _ frame: CGRect) -> CGRect {
        let actual = window.setFrame(frame) ?? frame
        snapController.updateSnappedFrame(window, to: actual)
        return actual
    }

    /// `frame` with the edges that moved by the same delta as the resized window's edges, or nil if none did.
    private func shifted(_ frame: CGRect, old: CGRect, new: CGRect) -> CGRect? {
        func edge(_ value: CGFloat, _ oldEdge: CGFloat, _ newEdge: CGFloat) -> CGFloat {
            abs(value - oldEdge) <= Self.tolerance ? value + (newEdge - oldEdge) : value
        }
        let minX = edge(frame.minX, old.minX, new.minX), maxX = edge(frame.maxX, old.maxX, new.maxX)
        let minY = edge(frame.minY, old.minY, new.minY), maxY = edge(frame.maxY, old.maxY, new.maxY)
        let result = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        return result == frame ? nil : result
    }

    /// Moves the edge of `frame` that touched the requested neighbour frame onto the neighbour's actual edge.
    private func corrected(_ frame: CGRect, requested: CGRect, actual: CGRect) -> CGRect {
        var minX = frame.minX, maxX = frame.maxX, minY = frame.minY, maxY = frame.maxY
        if abs(maxX - requested.minX) <= 1 { maxX = actual.minX }
        if abs(minX - requested.maxX) <= 1 { minX = actual.maxX }
        if abs(maxY - requested.minY) <= 1 { maxY = actual.minY }
        if abs(minY - requested.maxY) <= 1 { minY = actual.maxY }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    private func close(_ a: CGRect, _ b: CGRect) -> Bool {
        abs(a.minX - b.minX) <= 1 && abs(a.minY - b.minY) <= 1
            && abs(a.width - b.width) <= 1 && abs(a.height - b.height) <= 1
    }
}

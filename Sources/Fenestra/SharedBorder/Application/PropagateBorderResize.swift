import CoreGraphics

/// Shared border: when the user resizes a snapped window, the snapped windows sharing the moved
/// border follow it.
@MainActor
final class PropagateBorderResize: SnappedWindowResizeHandler {
    private static let tolerance: CGFloat = 4

    private let store: SnapStore
    private let settings: any SnapSettingsProvider

    init(store: SnapStore, settings: any SnapSettingsProvider) {
        self.store = store
        self.settings = settings
    }

    func windowResized(_ window: any WindowHandle, from old: CGRect, to new: CGRect) {
        let settings = settings.snapSettings
        guard settings.sharedBorderEnabled, let screenID = store.record(for: window)?.screenID else { return }
        var frames: [WindowRef: CGRect] = [:]
        for (other, record) in store.snappedWindows(on: screenID, excluding: window) {
            frames[WindowRef(other)] = record.snappedFrame
        }
        let changed = WindowRef(window)
        // Windows whose same-side edge sat on the moved edge follow it, as if dragged too.
        var pairs: [(WindowRef, CGRect, CGRect)] = [(changed, old, new)]
        for (other, frame) in frames {
            if let moved = SharedBorderGeometry.shifted(frame, old: old, new: new, tolerance: Self.tolerance) {
                pairs.append((other, frame, moved))
            }
        }
        let gap = settings.gap
        let neighbours = frames.map { BorderWindow(id: $0.key, frame: $0.value, minSize: .zero) }
        for (key, from, to) in pairs {
            let others = neighbours.filter { $0.id != key }
            let adjustments = SharedBorderResolver.adjustments(
                changed: key, oldFrame: from, newFrame: to,
                neighbours: others, minSizeOfChanged: .zero, tolerance: Self.tolerance, gap: gap)
            if key != changed { apply(key, to) }
            for adjustment in adjustments {
                let actual = apply(adjustment.id, adjustment.frame)
                if adjustment.id != key, !SharedBorderGeometry.close(actual, adjustment.frame) {
                    // The app refused (minimum size): pull the changed window back onto the real edge.
                    apply(key, SharedBorderGeometry.corrected(to, requested: adjustment.frame, actual: actual, gap: gap))
                }
            }
        }
    }

    /// Stores the final frame of the resized window at the end of the gesture.
    func resizeEnded(_ window: any WindowHandle) {
        guard settings.snapSettings.sharedBorderEnabled, let frame = window.frame else { return }
        store.updateSnappedFrame(window, to: frame)
    }

    /// Sets the frame, records what the window actually got, and returns it.
    @discardableResult
    private func apply(_ ref: WindowRef, _ frame: CGRect) -> CGRect {
        let actual = ref.window.setFrame(frame) ?? frame
        store.updateSnappedFrame(ref.window, to: actual)
        return actual
    }
}

import CoreGraphics
import Foundation

/// What the capture knows about a window on screen.
struct CapturedWindow: Sendable, Equatable {
    var bundleIdentifier: String?
    var appName: String?
    var title: String?
    /// AX coordinates.
    var frame: CGRect
    /// The zone the window is still snapped in, if any.
    var zone: Zone?
    var pid: pid_t = 0
}

/// A window of the stacking order (front to back), as the window server lists it.
struct StackedWindow: Sendable, Equatable {
    var pid: pid_t
    /// AX coordinates.
    var frame: CGRect
}

/// Turns the windows on screen into the `LayoutSpec` that puts them back. Pure.
enum WorkspaceCapture {
    /// `windows` front to back: the Accessibility API lists windows per app, so the stacking order comes from
    /// the window server and each window is matched by process and frame (`WindowMatcher`). Windows the
    /// stacking does not list keep their order, after the others.
    static func sorted(_ windows: [CapturedWindow], frontToBack stacking: [StackedWindow]) -> [CapturedWindow] {
        let candidates = stacking.enumerated().map {
            (id: $0.offset, window: WindowDescriptor(pid: $0.element.pid, frame: $0.element.frame, title: nil))
        }
        let ranked = windows.enumerated().map { index, window -> (window: CapturedWindow, rank: Int, index: Int) in
            let target = WindowDescriptor(pid: window.pid, frame: window.frame, title: nil)
            return (window, WindowMatcher.bestMatch(for: target, among: candidates) ?? Int.max, index)
        }
        return ranked.sorted { ($0.rank, $0.index) < ($1.rank, $1.index) }.map(\.window)
    }

    /// One placement per window, in the given order (the first one ends up in front when applied).
    /// - app: the bundle identifier, or the app name without one; a window with neither is skipped;
    /// - display: the index in reading order of the display holding the window;
    /// - zone when the window is snapped, otherwise its frame in fractions of the display's usable area,
    ///   undoing the gap so that applying the layout gives the same frame back;
    /// - title only when the app has several windows in the capture, to tell them apart.
    static func layout(of windows: [CapturedWindow], screens: ScreenLayout, gap: CGFloat) -> LayoutSpec {
        let appCounts = Dictionary(windows.compactMap { app(of: $0) }.map { ($0, 1) }, uniquingKeysWith: +)
        var placements: [LayoutPlacement] = []
        for window in windows {
            guard let app = app(of: window), let screen = screens.screen(for: window.frame) else { continue }
            let title = appCounts[app, default: 0] > 1 ? window.title?.trimmingCharacters(in: .whitespaces) : nil
            let display = screens.readingOrder.firstIndex { $0.id == screen.id }.map { String($0 + 1) }
            var placement = LayoutPlacement(app: app, title: title?.isEmpty == false ? title : nil, display: display)
            if let zone = window.zone {
                placement.zone = zone
            } else {
                placement.rect = fraction(of: window.frame, in: screen.visibleFrame, gap: gap)
            }
            placements.append(placement)
        }
        return LayoutSpec(placements: placements)
    }

    private static func app(of window: CapturedWindow) -> String? {
        if let id = window.bundleIdentifier, !id.isEmpty { return id }
        if let name = window.appName, !name.isEmpty { return name }
        return nil
    }

    /// Inverse of `FractionRect.frame(in:gap:)`, clamped to the area; a window partly off screen is
    /// brought back inside.
    static func fraction(of frame: CGRect, in area: CGRect, gap: CGFloat) -> FractionRect {
        let half = max(0, gap) / 2
        let inner = area.insetBy(dx: half, dy: half)
        guard inner.width > 0, inner.height > 0 else { return FractionRect(x: 0, y: 0, width: 1, height: 1) }
        let raw = frame.insetBy(dx: -half, dy: -half)
        let width = min(1, max(0.01, raw.width / inner.width))
        let height = min(1, max(0.01, raw.height / inner.height))
        let x = round(min(1 - width, max(0, (raw.minX - inner.minX) / inner.width)))
        let y = round(min(1 - height, max(0, (raw.minY - inner.minY) / inner.height)))
        // Rounded sizes never push the rect past the area (`FractionRect.isValid`).
        return FractionRect(x: x, y: y, width: min(round(width), 1 - x), height: min(round(height), 1 - y))
    }

    /// Four decimals: enough for a point on any display, readable in the JSON file.
    private static func round(_ value: Double) -> Double {
        (value * 10_000).rounded() / 10_000
    }
}

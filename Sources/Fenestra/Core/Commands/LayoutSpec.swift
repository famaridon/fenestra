import CoreGraphics
import Foundation

/// A rectangle in fractions (0…1) of a display's visible area, origin top-left.
struct FractionRect: Codable, Sendable, Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    private static let epsilon = 0.0001

    var isValid: Bool {
        x >= 0 && y >= 0 && width > 0 && height > 0
            && x + width <= 1 + Self.epsilon && y + height <= 1 + Self.epsilon
    }

    /// Same gap rule as `Zone.frame(in:gap:)`: `area` is inset by `gap / 2`, then the rectangle too.
    func frame(in area: CGRect, gap: CGFloat) -> CGRect {
        let half = max(0, gap) / 2
        let a = area.insetBy(dx: half, dy: half)
        let raw = CGRect(x: a.minX + x * a.width, y: a.minY + y * a.height,
                         width: width * a.width, height: height * a.height)
        return raw.insetBy(dx: half, dy: half).integral
    }
}

/// One window of a layout: which window (app + optional title), where (display + zone or rect).
struct LayoutPlacement: Codable, Sendable, Equatable {
    /// Bundle identifier or application name, case-insensitive.
    var app: String
    /// Part of the window title, case-insensitive. Without it, any window of the app.
    var title: String?
    /// See `ScreenLayout.screen(matching:)`. Without it, the primary display.
    var display: String?
    var zone: Zone?
    var rect: FractionRect?

    init(app: String, title: String? = nil, display: String? = nil, zone: Zone? = nil, rect: FractionRect? = nil) {
        self.app = app
        self.title = title
        self.display = display
        self.zone = zone
        self.rect = rect
    }
}

/// A complete arrangement applied in one go. Windows it does not mention are left alone.
struct LayoutSpec: Codable, Sendable, Equatable {
    var placements: [LayoutPlacement]
    /// Opens the apps that have no matching window, then waits for their windows.
    var launchApps: Bool?

    enum CodingKeys: String, CodingKey {
        case placements
        case launchApps = "launch_apps"
    }
}

/// What the planner knows about a window.
struct LayoutWindow: Sendable, Equatable {
    var bundleIdentifier: String?
    var appName: String?
    var title: String?
}

enum PlacementIssue: Error, Sendable, Equatable, CustomStringConvertible {
    case noTarget
    case ambiguousTarget
    case invalidRect
    case unknownDisplay(String)
    case noWindow

    var description: String {
        switch self {
        case .noTarget: "give either a zone or a rect"
        case .ambiguousTarget: "give a zone or a rect, not both"
        case .invalidRect: "rect must have x, y >= 0, width, height > 0 and fit inside 0…1"
        case .unknownDisplay(let name): "unknown display \"\(name)\""
        case .noWindow: "no matching window"
        }
    }
}

struct PlannedPlacement: Sendable, Equatable {
    var windowIndex: Int
    var screen: ScreenInfo
    var zone: Zone?
    var frame: CGRect
}

/// Turns a `LayoutSpec` into window frames. Pure.
enum LayoutPlanner {
    static func matches(_ placement: LayoutPlacement, _ window: LayoutWindow) -> Bool {
        let app = placement.app.trimmingCharacters(in: .whitespaces)
        let appMatches = [window.bundleIdentifier, window.appName].contains {
            $0?.caseInsensitiveCompare(app) == .orderedSame
        }
        guard appMatches else { return false }
        guard let title = placement.title, !title.isEmpty else { return true }
        return window.title?.localizedCaseInsensitiveContains(title) ?? false
    }

    /// Index of the window given to each placement; each window is used once. Placements with a
    /// title pick first, so a generic placement never takes the window a titled one asked for.
    /// Among candidates, the first in `windows` (front-most) wins.
    static func assign(_ placements: [LayoutPlacement], to windows: [LayoutWindow]) -> [Int?] {
        var result = [Int?](repeating: nil, count: placements.count)
        var used = Set<Int>()
        let titledFirst = placements.indices.sorted { lhs, rhs in
            let l = placements[lhs].title?.isEmpty == false, r = placements[rhs].title?.isEmpty == false
            return l != r ? l : lhs < rhs
        }
        for p in titledFirst {
            if let w = windows.indices.first(where: { !used.contains($0) && matches(placements[p], windows[$0]) }) {
                result[p] = w
                used.insert(w)
            }
        }
        return result
    }

    static func targetFrame(for placement: LayoutPlacement, on screen: ScreenInfo,
                            gap: CGFloat) -> Result<(Zone?, CGRect), PlacementIssue> {
        switch (placement.zone, placement.rect) {
        case (nil, nil): return .failure(.noTarget)
        case (.some, .some): return .failure(.ambiguousTarget)
        case (.some(let zone), nil): return .success((zone, zone.frame(in: screen.visibleFrame, gap: gap)))
        case (nil, .some(let rect)):
            guard rect.isValid else { return .failure(.invalidRect) }
            return .success((nil, rect.frame(in: screen.visibleFrame, gap: gap)))
        }
    }

    static func plan(_ spec: LayoutSpec, windows: [LayoutWindow], layout: ScreenLayout,
                     gap: CGFloat) -> [Result<PlannedPlacement, PlacementIssue>] {
        let assignment = assign(spec.placements, to: windows)
        return spec.placements.indices.map { i in
            let placement = spec.placements[i]
            guard let screen = layout.screen(matching: placement.display) else {
                return .failure(.unknownDisplay(placement.display ?? ""))
            }
            let target: (Zone?, CGRect)
            switch targetFrame(for: placement, on: screen, gap: gap) {
            case .failure(let issue): return .failure(issue)
            case .success(let value): target = value
            }
            guard let windowIndex = assignment[i] else { return .failure(.noWindow) }
            return .success(PlannedPlacement(windowIndex: windowIndex, screen: screen, zone: target.0, frame: target.1))
        }
    }
}

extension ScreenLayout {
    /// Display named by a selector:
    /// - nil, "" or "primary"/"main": the display holding the menu bar (AX origin);
    /// - "1", "2"…: position in reading order (left to right, then top to bottom);
    /// - "left", "right", "top", "bottom": the outermost display on that side;
    /// - a display id as returned by `list_displays`, prefixed with "id:".
    func screen(matching selector: String?) -> ScreenInfo? {
        let key = (selector ?? "").trimmingCharacters(in: .whitespaces).lowercased()
        switch key {
        case "", "primary", "main":
            return screens.first { $0.frame.origin == .zero } ?? screens.first
        case "left": return screens.min { $0.frame.midX < $1.frame.midX }
        case "right": return screens.max { $0.frame.midX < $1.frame.midX }
        case "top": return screens.min { $0.frame.midY < $1.frame.midY }
        case "bottom": return screens.max { $0.frame.midY < $1.frame.midY }
        default:
            if key.hasPrefix("id:"), let id = UInt32(key.dropFirst(3)) { return screen(id: id) }
            if let index = Int(key), index >= 1, index <= screens.count { return readingOrder[index - 1] }
            return nil
        }
    }
}

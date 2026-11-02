import CoreGraphics

/// Results of the external control commands, encoded as JSON for the `fenestra` tool.
enum ControlResults {
    struct Rect: Codable, Sendable, Equatable {
        var x: Double, y: Double, width: Double, height: Double
        init(_ r: CGRect) { x = r.minX; y = r.minY; width = r.width; height = r.height }
    }

    struct DisplayInfo: Codable, Sendable, Equatable {
        var index: Int
        var id: UInt32
        var isPrimary: Bool
        var orientation: String
        var frame: Rect
        var visibleFrame: Rect
    }

    struct WindowInfo: Codable, Sendable, Equatable {
        var app: String?
        var bundleIdentifier: String?
        var title: String?
        var display: Int?
        var zone: Zone?
        var frame: Rect?
    }

    struct PlacedWindow: Codable, Sendable, Equatable {
        var placement: Int
        var app: String?
        var title: String?
        var display: Int
        var zone: Zone?
        var frame: Rect
    }

    struct FailedPlacement: Codable, Sendable, Equatable {
        var placement: Int
        var app: String
        var reason: String
    }

    struct LayoutReport: Codable, Sendable, Equatable {
        var placed: [PlacedWindow]
        var failed: [FailedPlacement]
    }
}

extension ScreenLayout {
    /// 1-based index of a screen in reading order, as used by `list_displays`.
    func displayIndex(of screen: ScreenInfo) -> Int? {
        readingOrder.firstIndex { $0.id == screen.id }.map { $0 + 1 }
    }
}

/// Launches applications by bundle identifier or name (port).
@MainActor
protocol AppLauncher: AnyObject {
    /// Launches each app (activating it, so a running app without windows opens one); unknown apps are skipped.
    func launch(_ apps: [String]) async
}

import CoreGraphics
@testable import Panes

/// Shared fixtures: a landscape primary display and a portrait display to its right (AX coordinates).
enum Fixtures {
    static let primary = ScreenInfo(
        id: 1,
        frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
        visibleFrame: CGRect(x: 0, y: 25, width: 1920, height: 1055)
    )
    static let portrait = ScreenInfo(
        id: 2,
        frame: CGRect(x: 1920, y: -420, width: 1080, height: 1920),
        visibleFrame: CGRect(x: 1920, y: -420, width: 1080, height: 1900)
    )
    static let twoScreens = ScreenLayout(screens: [primary, portrait])
}

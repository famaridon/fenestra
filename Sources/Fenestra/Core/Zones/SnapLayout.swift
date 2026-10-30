import Foundation

/// A set of zones shown together in the Snap Layouts palette, as on Windows 11.
struct SnapLayout: Hashable, Sendable, Identifiable {
    let zones: [Zone]

    var id: String { zones.map(\.rawValue).joined(separator: "+") }

    private static let landscape: [SnapLayout] = [
        SnapLayout(zones: [.leftHalf, .rightHalf]),
        SnapLayout(zones: [.leftHalf, .topRight, .bottomRight]),
        SnapLayout(zones: [.topLeft, .bottomLeft, .rightHalf]),
        SnapLayout(zones: [.topLeft, .topRight, .bottomLeft, .bottomRight]),
        SnapLayout(zones: [.leftThird, .centerThird, .rightThird]),
        SnapLayout(zones: [.leftTwoThirds, .rightThird]),
        SnapLayout(zones: [.leftThird, .rightTwoThirds]),
        SnapLayout(zones: [.maximize]),
    ]

    /// Thirds are columns: too narrow on a vertical display.
    private static let portrait: [SnapLayout] = [
        SnapLayout(zones: [.topHalf, .bottomHalf]),
        SnapLayout(zones: [.topHalf, .bottomLeft, .bottomRight]),
        SnapLayout(zones: [.topLeft, .topRight, .bottomHalf]),
        SnapLayout(zones: [.topLeft, .topRight, .bottomLeft, .bottomRight]),
        SnapLayout(zones: [.maximize]),
    ]

    /// Layouts offered on a display, keeping only those whose zones are all enabled.
    static func available(for orientation: ScreenOrientation, enabledZones: Set<Zone>) -> [SnapLayout] {
        let all = orientation == .portrait ? portrait : landscape
        return all.filter { $0.zones.allSatisfy(enabledZones.contains) }
    }
}

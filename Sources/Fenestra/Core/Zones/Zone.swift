import CoreGraphics
import Foundation

/// A region of a screen a window can be snapped to.
enum Zone: String, CaseIterable, Codable, Sendable, Identifiable, Hashable {
    case leftHalf, rightHalf, topHalf, bottomHalf
    case topLeft, topRight, bottomLeft, bottomRight
    case maximize
    case leftThird, centerThird, rightThird, leftTwoThirds, rightTwoThirds

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .leftHalf: "Moitié gauche"
        case .rightHalf: "Moitié droite"
        case .topHalf: "Moitié haute"
        case .bottomHalf: "Moitié basse"
        case .topLeft: "Quart haut gauche"
        case .topRight: "Quart haut droit"
        case .bottomLeft: "Quart bas gauche"
        case .bottomRight: "Quart bas droit"
        case .maximize: "Plein écran"
        case .leftThird: "Tiers gauche"
        case .centerThird: "Tiers central"
        case .rightThird: "Tiers droit"
        case .leftTwoThirds: "Deux tiers gauches"
        case .rightTwoThirds: "Deux tiers droits"
        }
    }

    var systemImage: String {
        switch self {
        case .leftHalf: "rectangle.lefthalf.filled"
        case .rightHalf: "rectangle.righthalf.filled"
        case .topHalf: "rectangle.tophalf.filled"
        case .bottomHalf: "rectangle.bottomhalf.filled"
        case .topLeft: "rectangle.inset.topleft.filled"
        case .topRight: "rectangle.inset.topright.filled"
        case .bottomLeft: "rectangle.inset.bottomleft.filled"
        case .bottomRight: "rectangle.inset.bottomright.filled"
        case .maximize: "rectangle.fill"
        case .leftThird, .leftTwoThirds: "rectangle.leadingthird.inset.filled"
        case .centerThird: "rectangle.center.inset.filled"
        case .rightThird, .rightTwoThirds: "rectangle.trailingthird.inset.filled"
        }
    }

    /// Zones that are only reachable from the keyboard.
    var isThird: Bool {
        switch self {
        case .leftThird, .centerThird, .rightThird, .leftTwoThirds, .rightTwoThirds: true
        default: false
        }
    }

    static let defaultEnabled: Set<Zone> = Set(Zone.allCases.filter { !$0.isThird })

    /// The zone filling the space left over by this one (used by Snap Assist).
    var complement: Zone? {
        switch self {
        case .leftHalf: .rightHalf
        case .rightHalf: .leftHalf
        case .topHalf: .bottomHalf
        case .bottomHalf: .topHalf
        case .topLeft: .bottomLeft
        case .bottomLeft: .topLeft
        case .topRight: .bottomRight
        case .bottomRight: .topRight
        case .maximize, .leftThird, .centerThird, .rightThird, .leftTwoThirds, .rightTwoThirds: nil
        }
    }

    /// Whether both zones cover a common area of the same screen (sharing an edge does not count).
    func overlaps(_ other: Zone) -> Bool {
        // Divisible by 2 and 3, so `frame(in:gap:)`'s rounding to whole points never shifts an edge.
        let reference = CGRect(x: 0, y: 0, width: 1200, height: 1200)
        let shared = frame(in: reference, gap: 0).intersection(other.frame(in: reference, gap: 0))
        return !shared.isNull && shared.width > 0 && shared.height > 0
    }

    /// Frame of the zone inside `area` (the screen's visible frame, AX coordinates).
    /// `gap` is the margin between windows and with the screen edges: `area` is inset by
    /// `gap / 2`, then each zone is inset by `gap / 2` on every side.
    func frame(in area: CGRect, gap: CGFloat) -> CGRect {
        let half = max(0, gap) / 2
        let a = area.insetBy(dx: half, dy: half)
        let w = a.width, h = a.height
        let raw: CGRect
        switch self {
        case .maximize: raw = a
        case .leftHalf: raw = CGRect(x: a.minX, y: a.minY, width: w / 2, height: h)
        case .rightHalf: raw = CGRect(x: a.midX, y: a.minY, width: w / 2, height: h)
        case .topHalf: raw = CGRect(x: a.minX, y: a.minY, width: w, height: h / 2)
        case .bottomHalf: raw = CGRect(x: a.minX, y: a.midY, width: w, height: h / 2)
        case .topLeft: raw = CGRect(x: a.minX, y: a.minY, width: w / 2, height: h / 2)
        case .topRight: raw = CGRect(x: a.midX, y: a.minY, width: w / 2, height: h / 2)
        case .bottomLeft: raw = CGRect(x: a.minX, y: a.midY, width: w / 2, height: h / 2)
        case .bottomRight: raw = CGRect(x: a.midX, y: a.midY, width: w / 2, height: h / 2)
        case .leftThird: raw = CGRect(x: a.minX, y: a.minY, width: w / 3, height: h)
        case .centerThird: raw = CGRect(x: a.minX + w / 3, y: a.minY, width: w / 3, height: h)
        case .rightThird: raw = CGRect(x: a.minX + 2 * w / 3, y: a.minY, width: w / 3, height: h)
        case .leftTwoThirds: raw = CGRect(x: a.minX, y: a.minY, width: 2 * w / 3, height: h)
        case .rightTwoThirds: raw = CGRect(x: a.minX + w / 3, y: a.minY, width: 2 * w / 3, height: h)
        }
        return raw.insetBy(dx: half, dy: half).integral
    }
}

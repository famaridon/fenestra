import CoreGraphics
import Foundation

/// What a window is currently snapped to.
struct WindowSnapState: Sendable, Equatable {
    var zone: Zone
    var screenID: CGDirectDisplayID
}

/// What the controller must do after a keyboard action.
enum SnapCommand: Sendable, Equatable {
    case place(Zone, on: ScreenInfo)
    case restore
    case none
}

/// Pure decision table for keyboard snapping (see ARCHITECTURE.md).
struct KeyboardSnapResolver: Sendable {
    /// Portrait screens: ← / → cut the top or bottom half into quarters, mirroring how ↑ / ↓ cut
    /// a side half on landscape screens. Off: quarters come from the left / right halves, as on landscape.
    var portraitArrowsSplitHalves = true

    /// `state` is nil when the window is not snapped. `screen` is the window's current screen.
    /// A state recorded on another screen is treated as "not snapped".
    func command(for action: SnapAction, state: WindowSnapState?, on screen: ScreenInfo, layout: ScreenLayout) -> SnapCommand {
        let zone: Zone? = (state?.screenID == screen.id) ? state?.zone : nil
        let portrait = screen.orientation == .portrait

        switch action {
        case .left, .right:
            let direction: Direction = action == .left ? .left : .right
            if portrait, portraitArrowsSplitHalves, let split = splitHalf(direction, zone: zone, screen: screen) {
                return split
            }
            return horizontal(direction, zone: zone, screen: screen, layout: layout)
        case .up:
            return portrait ? upPortrait(zone: zone, screen: screen, layout: layout) : upLandscape(zone: zone, screen: screen)
        case .down:
            return portrait ? downPortrait(zone: zone, screen: screen, layout: layout) : downLandscape(zone: zone, screen: screen)
        case .topLeft: return direct(.topLeft, zone, screen)
        case .topRight: return direct(.topRight, zone, screen)
        case .bottomLeft: return direct(.bottomLeft, zone, screen)
        case .bottomRight: return direct(.bottomRight, zone, screen)
        case .maximize: return direct(.maximize, zone, screen)
        case .leftThird: return direct(.leftThird, zone, screen)
        case .centerThird: return direct(.centerThird, zone, screen)
        case .rightThird: return direct(.rightThird, zone, screen)
        case .leftTwoThirds: return direct(.leftTwoThirds, zone, screen)
        case .rightTwoThirds: return direct(.rightTwoThirds, zone, screen)
        case .restore:
            return zone == nil ? .none : .restore
        case .nextDisplay, .previousDisplay:
            // Not snapped: the controller moves the window proportionally.
            guard let zone else { return .none }
            let other = action == .nextDisplay ? layout.next(after: screen) : layout.previous(before: screen)
            return other.map { .place(zone, on: $0) } ?? .none
        }
    }

    /// Direct placement: place the zone on the current screen unless it is already there.
    private func direct(_ target: Zone, _ current: Zone?, _ screen: ScreenInfo) -> SnapCommand {
        current == target ? .none : .place(target, on: screen)
    }

    // MARK: Left / right (same in both orientations)

    private func horizontal(_ direction: Direction, zone: Zone?, screen: ScreenInfo, layout: ScreenLayout) -> SnapCommand {
        let isLeft = direction == .left
        // Zones on the side we are heading to and on the opposite side (index-aligned:
        // half, top quarter, bottom quarter). The opposite zone is also the mirror on the neighbour.
        let towards: [Zone] = isLeft ? [.leftHalf, .topLeft, .bottomLeft] : [.rightHalf, .topRight, .bottomRight]
        let opposite: [Zone] = isLeft ? [.rightHalf, .topRight, .bottomRight] : [.leftHalf, .topLeft, .bottomLeft]

        guard let zone else { return .place(isLeft ? .leftHalf : .rightHalf, on: screen) }
        if let i = opposite.firstIndex(of: zone) {
            return .place(towards[i], on: screen)
        }
        if let i = towards.firstIndex(of: zone) {
            // Already on that side: hop to the neighbouring screen, arriving on the opposite side.
            guard let neighbour = layout.neighbor(of: screen, toward: direction) else { return .restore }
            return .place(opposite[i], on: neighbour)
        }
        // maximize, topHalf, bottomHalf, thirds
        return .place(isLeft ? .leftHalf : .rightHalf, on: screen)
    }

    /// Portrait with `portraitArrowsSplitHalves`: a top or bottom half and its quarters.
    /// Nil for every other zone, which falls back to `horizontal`.
    private func splitHalf(_ direction: Direction, zone: Zone?, screen: ScreenInfo) -> SnapCommand? {
        let isLeft = direction == .left
        switch zone {
        case .topHalf: return .place(isLeft ? .topLeft : .topRight, on: screen)
        case .bottomHalf: return .place(isLeft ? .bottomLeft : .bottomRight, on: screen)
        // Back to the whole half from the other quarter.
        case .topRight where isLeft, .topLeft where !isLeft: return .place(.topHalf, on: screen)
        case .bottomRight where isLeft, .bottomLeft where !isLeft: return .place(.bottomHalf, on: screen)
        default: return nil
        }
    }

    // MARK: Up / down

    private func upLandscape(zone: Zone?, screen: ScreenInfo) -> SnapCommand {
        switch zone {
        case .leftHalf: .place(.topLeft, on: screen)
        case .rightHalf: .place(.topRight, on: screen)
        case .bottomLeft: .place(.leftHalf, on: screen)
        case .bottomRight: .place(.rightHalf, on: screen)
        case .maximize, .topLeft, .topRight: .none
        default: .place(.maximize, on: screen)  // nil, topHalf, bottomHalf, thirds
        }
    }

    private func upPortrait(zone: Zone?, screen: ScreenInfo, layout: ScreenLayout) -> SnapCommand {
        switch zone {
        case .topHalf: return .place(.maximize, on: screen)
        case .bottomHalf:
            if let up = layout.neighbor(of: screen, toward: .up) { return .place(.bottomHalf, on: up) }
            return .place(.topHalf, on: screen)
        case .leftHalf: return .place(.topLeft, on: screen)
        case .rightHalf: return .place(.topRight, on: screen)
        case .bottomLeft: return .place(portraitArrowsSplitHalves ? .topLeft : .leftHalf, on: screen)
        case .bottomRight: return .place(portraitArrowsSplitHalves ? .topRight : .rightHalf, on: screen)
        case .maximize, .topLeft, .topRight: return .none
        default: return .place(.topHalf, on: screen)  // nil, thirds
        }
    }

    private func downLandscape(zone: Zone?, screen: ScreenInfo) -> SnapCommand {
        switch zone {
        case nil: .none
        case .leftHalf: .place(.bottomLeft, on: screen)
        case .rightHalf: .place(.bottomRight, on: screen)
        case .topLeft: .place(.leftHalf, on: screen)
        case .topRight: .place(.rightHalf, on: screen)
        default: .restore  // maximize, bottom quarters, top/bottom halves, thirds
        }
    }

    private func downPortrait(zone: Zone?, screen: ScreenInfo, layout: ScreenLayout) -> SnapCommand {
        switch zone {
        case .maximize, .bottomHalf, .bottomLeft, .bottomRight: return .restore
        case .topHalf:
            if let down = layout.neighbor(of: screen, toward: .down) { return .place(.topHalf, on: down) }
            return .place(.bottomHalf, on: screen)
        case .leftHalf: return .place(.bottomLeft, on: screen)
        case .rightHalf: return .place(.bottomRight, on: screen)
        case .topLeft: return .place(portraitArrowsSplitHalves ? .bottomLeft : .leftHalf, on: screen)
        case .topRight: return .place(portraitArrowsSplitHalves ? .bottomRight : .rightHalf, on: screen)
        default: return .place(.bottomHalf, on: screen)  // nil, thirds
        }
    }
}

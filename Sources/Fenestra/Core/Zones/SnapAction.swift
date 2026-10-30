import Foundation

/// An action triggered from the keyboard (or the menu).
enum SnapAction: String, CaseIterable, Codable, Sendable, Identifiable, Hashable {
    case left, right, up, down
    case topLeft, topRight, bottomLeft, bottomRight
    case maximize, restore
    case nextDisplay, previousDisplay
    case leftThird, centerThird, rightThird, leftTwoThirds, rightTwoThirds

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .left: String(localized: "Move Left")
        case .right: String(localized: "Move Right")
        case .up: String(localized: "Move Up")
        case .down: String(localized: "Move Down")
        case .topLeft: Zone.topLeft.localizedName
        case .topRight: Zone.topRight.localizedName
        case .bottomLeft: Zone.bottomLeft.localizedName
        case .bottomRight: Zone.bottomRight.localizedName
        case .maximize: Zone.maximize.localizedName
        case .restore: String(localized: "Restore Size")
        case .nextDisplay: String(localized: "Next Display")
        case .previousDisplay: String(localized: "Previous Display")
        case .leftThird: Zone.leftThird.localizedName
        case .centerThird: Zone.centerThird.localizedName
        case .rightThird: Zone.rightThird.localizedName
        case .leftTwoThirds: Zone.leftTwoThirds.localizedName
        case .rightTwoThirds: Zone.rightTwoThirds.localizedName
        }
    }

    /// Fixed zone for actions that always map to the same zone; nil for directional actions.
    var fixedZone: Zone? {
        switch self {
        case .topLeft: .topLeft
        case .topRight: .topRight
        case .bottomLeft: .bottomLeft
        case .bottomRight: .bottomRight
        case .maximize: .maximize
        case .leftThird: .leftThird
        case .centerThird: .centerThird
        case .rightThird: .rightThird
        case .leftTwoThirds: .leftTwoThirds
        case .rightTwoThirds: .rightTwoThirds
        case .left, .right, .up, .down, .restore, .nextDisplay, .previousDisplay: nil
        }
    }

    var defaultShortcut: KeyboardShortcut? {
        typealias K = KeyboardShortcut.Key
        let co = KeyboardShortcut.controlFlag | KeyboardShortcut.optionFlag
        let coc = co | KeyboardShortcut.commandFlag
        switch self {
        case .left: return KeyboardShortcut(keyCode: K.left, modifiers: co)
        case .right: return KeyboardShortcut(keyCode: K.right, modifiers: co)
        case .up: return KeyboardShortcut(keyCode: K.up, modifiers: co)
        case .down: return KeyboardShortcut(keyCode: K.down, modifiers: co)
        case .topLeft: return KeyboardShortcut(keyCode: K.u, modifiers: co)
        case .topRight: return KeyboardShortcut(keyCode: K.i, modifiers: co)
        case .bottomLeft: return KeyboardShortcut(keyCode: K.j, modifiers: co)
        case .bottomRight: return KeyboardShortcut(keyCode: K.k, modifiers: co)
        case .maximize: return KeyboardShortcut(keyCode: K.returnKey, modifiers: co)
        case .restore: return KeyboardShortcut(keyCode: K.delete, modifiers: co)
        case .nextDisplay: return KeyboardShortcut(keyCode: K.right, modifiers: coc)
        case .previousDisplay: return KeyboardShortcut(keyCode: K.left, modifiers: coc)
        case .leftThird, .centerThird, .rightThird, .leftTwoThirds, .rightTwoThirds: return nil
        }
    }

    static var defaultShortcuts: [SnapAction: KeyboardShortcut] {
        var result: [SnapAction: KeyboardShortcut] = [:]
        for action in allCases {
            if let shortcut = action.defaultShortcut { result[action] = shortcut }
        }
        return result
    }
}

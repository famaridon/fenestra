import Foundation

/// Shortcuts of Magnet (https://magnet.crowdcafe.com), read from its preferences.
///
/// Each action is a `…ComboKey` key holding a MASShortcut-style dictionary. A key that was never written
/// means Magnet's factory shortcut, which is the same ⌃⌥ set as Fenestra's defaults (plus the thirds).
/// Only the keys observed in users' preferences are mapped: the display actions keep Fenestra's shortcuts,
/// which are Magnet's factory ones too.
enum MagnetShortcuts {
    static let domain = "com.crowdcafe.windowmagnet"

    static let mapping: [(key: String, action: SnapAction)] = [
        ("expandWindowWestComboKey", .left), ("expandWindowEastComboKey", .right),
        ("expandWindowNorthComboKey", .up), ("expandWindowSouthComboKey", .down),
        ("expandWindowNorthWestComboKey", .topLeft), ("expandWindowNorthEastComboKey", .topRight),
        ("expandWindowSouthWestComboKey", .bottomLeft), ("expandWindowSouthEastComboKey", .bottomRight),
        ("expandWindowLeftThirdComboKey", .leftThird), ("expandWindowCenterThirdComboKey", .centerThird),
        ("expandWindowRightThirdComboKey", .rightThird),
        ("expandWindowLeftTwoThirdsComboKey", .leftTwoThirds), ("expandWindowRightTwoThirdsComboKey", .rightTwoThirds),
        ("maximizeWindowComboKey", .maximize), ("restoreWindowComboKey", .restore),
    ]

    /// Magnet's factory shortcuts for the mapped actions.
    static var factoryDefaults: [SnapAction: KeyboardShortcut] {
        var result = RectangleShortcuts.recommendedDefaults
        result[.nextDisplay] = nil
        result[.previousDisplay] = nil
        return result
    }

    static func parse(_ preferences: [String: Any]) -> ImportedShortcuts {
        ImportedShortcuts.fromPreferences(preferences, mapping: mapping, defaults: factoryDefaults) { key in
            key.hasSuffix("ComboKey") ? String(key.dropLast("ComboKey".count)) : nil
        }
    }
}

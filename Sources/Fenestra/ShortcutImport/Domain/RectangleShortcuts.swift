import Foundation

/// Shortcuts of Rectangle (https://rectangleapp.com), read from its preferences.
///
/// Each action is a key named after the action (`leftHalf`, `topLeft`…) holding a MASShortcut dictionary.
/// A key that was never written means Rectangle's default: its "recommended" set (⌃⌥, like Magnet) when
/// `alternateDefaultShortcuts` is true, otherwise its Spectacle-like set.
enum RectangleShortcuts {
    static let domain = "com.knollsoft.Rectangle"

    /// Rectangle action -> Fenestra action. Halves map to the directional actions, which give the same
    /// half from an unsnapped window.
    static let mapping: [(key: String, action: SnapAction)] = [
        ("leftHalf", .left), ("rightHalf", .right), ("topHalf", .up), ("bottomHalf", .down),
        ("topLeft", .topLeft), ("topRight", .topRight), ("bottomLeft", .bottomLeft), ("bottomRight", .bottomRight),
        ("maximize", .maximize), ("restore", .restore),
        ("nextDisplay", .nextDisplay), ("previousDisplay", .previousDisplay),
        ("firstThird", .leftThird), ("centerThird", .centerThird), ("lastThird", .rightThird),
        ("firstTwoThirds", .leftTwoThirds), ("lastTwoThirds", .rightTwoThirds),
    ]

    /// Rectangle's "recommended" defaults: ⌃⌥ with the arrows, U I J K, ↩, ⌫, and D E F T G for the thirds.
    static var recommendedDefaults: [SnapAction: KeyboardShortcut] {
        typealias K = KeyboardShortcut.Key
        let co = KeyboardShortcut.controlFlag | KeyboardShortcut.optionFlag
        var result = SnapAction.defaultShortcuts
        result[.leftThird] = KeyboardShortcut(keyCode: K.d, modifiers: co)
        result[.leftTwoThirds] = KeyboardShortcut(keyCode: K.e, modifiers: co)
        result[.centerThird] = KeyboardShortcut(keyCode: K.f, modifiers: co)
        result[.rightTwoThirds] = KeyboardShortcut(keyCode: K.t, modifiers: co)
        result[.rightThird] = KeyboardShortcut(keyCode: K.g, modifiers: co)
        return result
    }

    /// Rectangle's Spectacle-like defaults (its original set): ⌘⌥ with the arrows and F, ⌃⌘ for the quarters.
    static var spectacleDefaults: [SnapAction: KeyboardShortcut] {
        typealias K = KeyboardShortcut.Key
        let cmdOpt = KeyboardShortcut.commandFlag | KeyboardShortcut.optionFlag
        let ctrlCmd = KeyboardShortcut.controlFlag | KeyboardShortcut.commandFlag
        let ctrlCmdShift = ctrlCmd | KeyboardShortcut.shiftFlag
        let ctrlOpt = KeyboardShortcut.controlFlag | KeyboardShortcut.optionFlag
        return [
            .left: KeyboardShortcut(keyCode: K.left, modifiers: cmdOpt),
            .right: KeyboardShortcut(keyCode: K.right, modifiers: cmdOpt),
            .up: KeyboardShortcut(keyCode: K.up, modifiers: cmdOpt),
            .down: KeyboardShortcut(keyCode: K.down, modifiers: cmdOpt),
            .maximize: KeyboardShortcut(keyCode: K.f, modifiers: cmdOpt),
            .topLeft: KeyboardShortcut(keyCode: K.left, modifiers: ctrlCmd),
            .topRight: KeyboardShortcut(keyCode: K.right, modifiers: ctrlCmd),
            .bottomLeft: KeyboardShortcut(keyCode: K.left, modifiers: ctrlCmdShift),
            .bottomRight: KeyboardShortcut(keyCode: K.right, modifiers: ctrlCmdShift),
            .restore: KeyboardShortcut(keyCode: K.delete, modifiers: ctrlOpt),
            .nextDisplay: KeyboardShortcut(keyCode: K.right, modifiers: ctrlOpt | KeyboardShortcut.commandFlag),
            .previousDisplay: KeyboardShortcut(keyCode: K.left, modifiers: ctrlOpt | KeyboardShortcut.commandFlag),
        ]
    }

    static func parse(_ preferences: [String: Any]) -> ImportedShortcuts {
        let recommended = (preferences["alternateDefaultShortcuts"] as? NSNumber)?.boolValue ?? false
        return ImportedShortcuts.fromPreferences(
            preferences, mapping: mapping, defaults: recommended ? recommendedDefaults : spectacleDefaults,
            unmappedKey: { key in Self.isActionKey(key) ? key : nil })
    }

    /// Rectangle stores every shortcut under its action's name, in lower camel case; its other preferences
    /// are flags and numbers, which `PreferenceShortcut` already rejects. Keys starting with an upper case
    /// letter or containing a dot (system keys such as `NSWindow Frame…`) are not actions.
    private static func isActionKey(_ key: String) -> Bool {
        guard let first = key.first else { return false }
        return first.isLowercase && !key.contains(".") && !key.contains(" ")
    }
}

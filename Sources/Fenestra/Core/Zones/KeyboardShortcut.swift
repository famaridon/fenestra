import Foundation

/// A global keyboard shortcut, stored as a virtual key code plus `NSEvent.ModifierFlags` raw value.
/// Pure value type: no AppKit import so it stays testable from Core.
struct KeyboardShortcut: Codable, Hashable, Sendable {
    var keyCode: UInt16
    /// `NSEvent.ModifierFlags.rawValue` restricted to ⇧ ⌃ ⌥ ⌘.
    var modifiers: UInt

    // NSEvent.ModifierFlags raw values.
    static let shiftFlag: UInt = 1 << 17
    static let controlFlag: UInt = 1 << 18
    static let optionFlag: UInt = 1 << 19
    static let commandFlag: UInt = 1 << 20
    static let relevantFlags: UInt = shiftFlag | controlFlag | optionFlag | commandFlag

    // Common virtual key codes.
    enum Key {
        static let returnKey: UInt16 = 36
        static let delete: UInt16 = 51
        static let left: UInt16 = 123
        static let right: UInt16 = 124
        static let down: UInt16 = 125
        static let up: UInt16 = 126
        static let u: UInt16 = 32
        static let i: UInt16 = 34
        static let j: UInt16 = 38
        static let k: UInt16 = 40
        static let d: UInt16 = 2
        static let e: UInt16 = 14
        static let f: UInt16 = 3
        static let g: UInt16 = 5
        static let t: UInt16 = 17
    }

    init(keyCode: UInt16, modifiers: UInt) {
        self.keyCode = keyCode
        self.modifiers = modifiers & Self.relevantFlags
    }

    /// Carbon modifier mask for `RegisterEventHotKey`.
    var carbonModifiers: UInt32 {
        var mask: UInt32 = 0
        if modifiers & Self.commandFlag != 0 { mask |= 0x0100 } // cmdKey
        if modifiers & Self.shiftFlag != 0 { mask |= 0x0200 }   // shiftKey
        if modifiers & Self.optionFlag != 0 { mask |= 0x0800 }  // optionKey
        if modifiers & Self.controlFlag != 0 { mask |= 0x1000 } // controlKey
        return mask
    }

    /// Human readable form, e.g. "⌃⌥←".
    var displayString: String {
        var s = ""
        if modifiers & Self.controlFlag != 0 { s += "⌃" }
        if modifiers & Self.optionFlag != 0 { s += "⌥" }
        if modifiers & Self.shiftFlag != 0 { s += "⇧" }
        if modifiers & Self.commandFlag != 0 { s += "⌘" }
        return s + Self.keyName(for: keyCode)
    }

    static func keyName(for keyCode: UInt16) -> String {
        switch keyCode {
        case Key.left: "←"
        case Key.right: "→"
        case Key.up: "↑"
        case Key.down: "↓"
        case Key.returnKey: "↩"
        case Key.delete: "⌫"
        case 53: "⎋"
        case 48: "⇥"
        case 49: "␣"
        case 0: "A"; case 11: "B"; case 8: "C"; case 2: "D"; case 14: "E"; case 3: "F"; case 5: "G"
        case 4: "H"; case 34: "I"; case 38: "J"; case 40: "K"; case 37: "L"; case 46: "M"; case 45: "N"
        case 31: "O"; case 35: "P"; case 12: "Q"; case 15: "R"; case 1: "S"; case 17: "T"; case 32: "U"
        case 9: "V"; case 13: "W"; case 7: "X"; case 16: "Y"; case 6: "Z"
        case 29: "0"; case 18: "1"; case 19: "2"; case 20: "3"; case 21: "4"; case 23: "5"
        case 22: "6"; case 26: "7"; case 28: "8"; case 25: "9"
        case 122: "F1"; case 120: "F2"; case 99: "F3"; case 118: "F4"; case 96: "F5"; case 97: "F6"
        case 98: "F7"; case 100: "F8"; case 101: "F9"; case 109: "F10"; case 103: "F11"; case 111: "F12"
        default: "⌨\(keyCode)"
        }
    }
}

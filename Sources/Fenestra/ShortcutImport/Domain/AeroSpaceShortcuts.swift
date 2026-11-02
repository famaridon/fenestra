import Foundation

/// Shortcuts of AeroSpace (https://nikitabobko.github.io/AeroSpace), read from its TOML configuration.
///
/// Only the `[mode.main.binding]` table is read: `alt-shift-h = 'move left'`, with one command or an array
/// of commands. AeroSpace is a tiling manager, so few of its commands have an equivalent: `move` in a
/// direction, `fullscreen`, and `move-node-to-monitor` left / right / prev / next. Key names are the
/// qwerty ones (`key-mapping.preset` is ignored).
enum AeroSpaceShortcuts {
    /// Where AeroSpace looks for its configuration, relative to the home folder, in order.
    static let configurationPaths = [".aerospace.toml", ".config/aerospace/aerospace.toml"]

    static func parse(_ toml: String) -> ImportedShortcuts {
        var result = ImportedShortcuts()
        for binding in mainBindings(in: toml) {
            let description = "\(binding.key) = \(binding.commands.joined(separator: ", "))"
            guard let action = action(for: binding.commands), let shortcut = shortcut(forKey: binding.key) else {
                result.unmapped.append(description)
                continue
            }
            result.shortcuts[action] = shortcut
        }
        return result
    }

    // MARK: Commands

    /// The first command with an equivalent. The direction is the last word: options (`--wrap-around`,
    /// `--boundaries <value>`…) come before it.
    static func action(for commands: [String]) -> SnapAction? {
        for command in commands {
            let words = command.split(whereSeparator: \.isWhitespace).map(String.init)
            guard let name = words.first else { continue }
            let argument = words.count > 1 ? words.last : nil
            switch (name, argument) {
            case ("fullscreen", _): return .maximize
            case ("move", "left"): return .left
            case ("move", "right"): return .right
            case ("move", "up"): return .up
            case ("move", "down"): return .down
            case ("move-node-to-monitor", "left"), ("move-node-to-monitor", "prev"): return .previousDisplay
            case ("move-node-to-monitor", "right"), ("move-node-to-monitor", "next"): return .nextDisplay
            default: continue
            }
        }
        return nil
    }

    // MARK: Keys

    /// `alt-shift-h` -> ⌥⇧H. nil for an unknown key or a binding without modifier.
    static func shortcut(forKey key: String) -> KeyboardShortcut? {
        let parts = key.split(separator: "-").map { $0.lowercased() }
        guard let last = parts.last, let keyCode = keyCodes[last] else { return nil }
        var modifiers: UInt = 0
        for part in parts.dropLast() {
            switch part {
            case "alt": modifiers |= KeyboardShortcut.optionFlag
            case "cmd": modifiers |= KeyboardShortcut.commandFlag
            case "ctrl": modifiers |= KeyboardShortcut.controlFlag
            case "shift": modifiers |= KeyboardShortcut.shiftFlag
            default: return nil
            }
        }
        guard modifiers != 0 else { return nil }
        return KeyboardShortcut(keyCode: keyCode, modifiers: modifiers)
    }

    /// AeroSpace key names (lower case) -> ANSI virtual key codes.
    static let keyCodes: [String: UInt16] = [
        "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7, "c": 8, "v": 9, "b": 11, "q": 12,
        "w": 13, "e": 14, "r": 15, "y": 16, "t": 17, "o": 31, "u": 32, "i": 34, "p": 35, "l": 37, "j": 38,
        "k": 40, "n": 45, "m": 46,
        "1": 18, "2": 19, "3": 20, "4": 21, "5": 23, "6": 22, "7": 26, "8": 28, "9": 25, "0": 29,
        "equal": 24, "minus": 27, "rightsquarebracket": 30, "leftsquarebracket": 33, "quote": 39,
        "semicolon": 41, "backslash": 42, "comma": 43, "slash": 44, "period": 47, "backtick": 50,
        "sectionsign": 10,
        "enter": 36, "tab": 48, "space": 49, "backspace": 51, "esc": 53, "forwarddelete": 117,
        "home": 115, "end": 119, "pageup": 116, "pagedown": 121,
        "left": 123, "right": 124, "down": 125, "up": 126,
        "f1": 122, "f2": 120, "f3": 99, "f4": 118, "f5": 96, "f6": 97, "f7": 98, "f8": 100, "f9": 101,
        "f10": 109, "f11": 103, "f12": 111, "f13": 105, "f14": 107, "f15": 113, "f16": 106, "f17": 64,
        "f18": 79, "f19": 80, "f20": 90,
        "keypad0": 82, "keypad1": 83, "keypad2": 84, "keypad3": 85, "keypad4": 86, "keypad5": 87,
        "keypad6": 88, "keypad7": 89, "keypad8": 91, "keypad9": 92, "keypaddecimalmark": 65,
        "keypadmultiply": 67, "keypadplus": 69, "keypadclear": 71, "keypaddivide": 75, "keypadenter": 76,
        "keypadminus": 78, "keypadequal": 81,
    ]

    // MARK: TOML

    struct Binding: Equatable {
        var key: String
        var commands: [String]
    }

    /// Entries of `[mode.main.binding]` (also written `mode.main.binding.<key>` under a parent table),
    /// in file order. Values are a string or an array of strings; anything else is skipped. This is a
    /// deliberately small reader of the subset of TOML that AeroSpace configurations use.
    static func mainBindings(in toml: String) -> [Binding] {
        var bindings: [Binding] = []
        var table = ""
        var lines = toml.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).map(String.init)[...]
        while let rawLine = lines.popFirst() {
            let line = stripComment(rawLine).trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("[") {
                guard !line.hasPrefix("[["), let end = line.firstIndex(of: "]") else { continue }
                table = line[line.index(after: line.startIndex)..<end].trimmingCharacters(in: .whitespaces)
                continue
            }
            guard let equal = line.firstIndex(of: "=") else { continue }
            let key = line[..<equal].trimmingCharacters(in: .whitespaces).trimmingCharacters(in: quotes)
            var value = line[line.index(after: equal)...].trimmingCharacters(in: .whitespaces)
            // Multi-line values: a `'''`/`"""` string or an array spanning several lines.
            if let delimiter = ["'''", "\"\"\""].first(where: { value.hasPrefix($0) }) {
                while !value.dropFirst(3).contains(delimiter), let next = lines.popFirst() {
                    value += "\n" + next
                }
            } else if value.hasPrefix("[") {
                while !value.contains("]"), let next = lines.popFirst() {
                    value += stripComment(next)
                }
            }
            let fullKey = table.isEmpty ? key : "\(table).\(key)"
            guard fullKey.hasPrefix("mode.main.binding."), let commands = strings(in: value) else { continue }
            let bindingKey = String(fullKey.dropFirst("mode.main.binding.".count))
            guard !bindingKey.contains(".") else { continue }
            bindings.append(Binding(key: bindingKey, commands: commands))
        }
        return bindings
    }

    private static let quotes = CharacterSet(charactersIn: "'\"")

    /// The text before a `#` that is outside quotes.
    private static func stripComment(_ line: String) -> String {
        var quote: Character?
        for index in line.indices {
            let character = line[index]
            if let open = quote {
                if character == open { quote = nil }
            } else if character == "'" || character == "\"" {
                quote = character
            } else if character == "#" {
                return String(line[..<index])
            }
        }
        return line
    }

    /// A quoted string -> [string]; an array of quoted strings -> its elements; nil otherwise.
    private static func strings(in value: String) -> [String]? {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("[") {
            guard let close = value.lastIndex(of: "]") else { return nil }
            let inner = value[value.index(after: value.startIndex)..<close]
            var elements: [String] = []
            for element in inner.split(separator: ",") {
                guard let string = quotedString(String(element)) else { continue }
                elements.append(string)
            }
            return elements
        }
        return quotedString(value).map { [$0] }
    }

    private static func quotedString(_ value: String) -> String? {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        for delimiter in ["'''", "\"\"\"", "'", "\""] {
            if value.hasPrefix(delimiter), value.hasSuffix(delimiter), value.count >= 2 * delimiter.count {
                let inner = value.dropFirst(delimiter.count).dropLast(delimiter.count)
                return inner.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }.joined(separator: " ")
            }
        }
        return nil
    }
}

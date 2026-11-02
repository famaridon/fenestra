import Testing
@testable import Fenestra

struct AeroSpaceShortcutsTests {
    private typealias K = KeyboardShortcut.Key
    private let opt = KeyboardShortcut.optionFlag
    private let optShift = KeyboardShortcut.optionFlag | KeyboardShortcut.shiftFlag

    /// An excerpt of the default configuration, with the shapes TOML allows for a binding.
    private let config = """
        config-version = 2
        after-startup-command = []
        key-mapping.preset = 'qwerty'

        [mode.main.binding]
            # See: https://nikitabobko.github.io/AeroSpace/commands#layout
            alt-slash = 'layout tiles horizontal vertical'
            alt-h = 'focus left'   # a trailing comment with 'quotes' and a # sign
            alt-shift-h = 'move left'
            alt-shift-j = "move down"
            alt-shift-k = ['move up', 'mode main']
            alt-shift-l = [
                'move right',  # multi-line array
                'mode main',
            ]
            alt-f = 'fullscreen --no-outer-gaps'
            ctrl-alt-cmd-right = 'move-node-to-monitor --wrap-around next'
            ctrl-alt-cmd-left = 'move-node-to-monitor prev'
            alt-enter = '''exec-and-forget osascript -e \\
            'tell application "Terminal" to activate' '''
            alt-1 = 'workspace 1'
            alt-shift-semicolon = 'mode service'

        [mode.service.binding]
            esc = ['reload-config', 'mode main']
            f = ['layout floating tiling', 'mode main']
            alt-shift-h = ['join-with left', 'mode main']
        """

    @Test func readsTheBindingsOfTheMainMode() {
        let bindings = AeroSpaceShortcuts.mainBindings(in: config)
        #expect(bindings.map(\.key) == [
            "alt-slash", "alt-h", "alt-shift-h", "alt-shift-j", "alt-shift-k", "alt-shift-l", "alt-f",
            "ctrl-alt-cmd-right", "ctrl-alt-cmd-left", "alt-enter", "alt-1", "alt-shift-semicolon",
        ])
        #expect(bindings[1].commands == ["focus left"])
        #expect(bindings[4].commands == ["move up", "mode main"])
        #expect(bindings[5].commands == ["move right", "mode main"])
        #expect(bindings[9].commands.first?.hasPrefix("exec-and-forget osascript") == true)
    }

    @Test func mapsMoveFullscreenAndMonitorCommands() {
        let result = AeroSpaceShortcuts.parse(config)
        #expect(result.shortcuts == [
            .left: KeyboardShortcut(keyCode: 4, modifiers: optShift),
            .down: KeyboardShortcut(keyCode: K.j, modifiers: optShift),
            .up: KeyboardShortcut(keyCode: K.k, modifiers: optShift),
            .right: KeyboardShortcut(keyCode: 37, modifiers: optShift),
            .maximize: KeyboardShortcut(keyCode: K.f, modifiers: opt),
            .nextDisplay: SnapAction.nextDisplay.defaultShortcut!,
            .previousDisplay: SnapAction.previousDisplay.defaultShortcut!,
        ])
        #expect(result.cleared.isEmpty)
        #expect(result.unmapped.contains("alt-h = focus left"))
        #expect(result.unmapped.contains("alt-slash = layout tiles horizontal vertical"))
        #expect(result.unmapped.contains("alt-shift-semicolon = mode service"))
        #expect(result.unmapped.count == 5)
    }

    @Test func dottedKeysUnderAParentTableCount() {
        let toml = """
            [mode.main]
            binding.alt-f = 'fullscreen'
            [mode]
            main.binding.alt-shift-h = 'move left'
            service.binding.alt-shift-h = 'join-with left'
            """
        let result = AeroSpaceShortcuts.parse(toml)
        #expect(result.shortcuts[.maximize] == KeyboardShortcut(keyCode: K.f, modifiers: opt))
        #expect(result.shortcuts[.left] == KeyboardShortcut(keyCode: 4, modifiers: optShift))
        #expect(result.unmapped.isEmpty)
    }

    @Test func keysWithoutModifierOrUnknownAreNotShortcuts() {
        #expect(AeroSpaceShortcuts.shortcut(forKey: "f") == nil)
        #expect(AeroSpaceShortcuts.shortcut(forKey: "alt-unknownkey") == nil)
        #expect(AeroSpaceShortcuts.shortcut(forKey: "hyper-f") == nil)
        #expect(AeroSpaceShortcuts.shortcut(forKey: "cmd-ctrl-keypad5") == KeyboardShortcut(
            keyCode: 87, modifiers: KeyboardShortcut.commandFlag | KeyboardShortcut.controlFlag))
        #expect(AeroSpaceShortcuts.shortcut(forKey: "Alt-Shift-F12") == KeyboardShortcut(keyCode: 111, modifiers: optShift))
        let result = AeroSpaceShortcuts.parse("[mode.main.binding]\nf = 'fullscreen'\n")
        #expect(result.shortcuts.isEmpty)
        #expect(result.unmapped == ["f = fullscreen"])
    }

    @Test func onlyTheMappedDirectionsOfMoveNodeToMonitorCount() {
        #expect(AeroSpaceShortcuts.action(for: ["move-node-to-monitor up"]) == nil)
        #expect(AeroSpaceShortcuts.action(for: ["move-node-to-monitor --focus-follows-window left"]) == .previousDisplay)
        #expect(AeroSpaceShortcuts.action(for: ["move-node-to-monitor right", "mode main"]) == .nextDisplay)
        #expect(AeroSpaceShortcuts.action(for: ["mode main", "fullscreen on"]) == .maximize)
        #expect(AeroSpaceShortcuts.action(for: ["macos-native-fullscreen"]) == nil)
        #expect(AeroSpaceShortcuts.action(for: ["move --boundaries all-monitors-outer-frame left"]) == .left)
    }
}

import Foundation
import Testing
@testable import Fenestra

struct MagnetShortcutsTests {
    private typealias K = KeyboardShortcut.Key
    private let ctrlOpt = KeyboardShortcut.controlFlag | KeyboardShortcut.optionFlag

    private func combo(_ keyCode: Int, _ flags: UInt) -> [String: Any] {
        ["keyCode": NSNumber(value: keyCode), "modifierFlags": NSNumber(value: flags)]
    }

    @Test func readsTheShortcutsTheUserSet() {
        let result = MagnetShortcuts.parse([
            "expandWindowWestComboKey": combo(123, 1_310_720),       // ⌃⌘←
            "expandWindowNorthEastComboKey": combo(14, 786_432),     // ⌃⌥E
            "expandWindowLeftTwoThirdsComboKey": combo(41, 786_432), // ⌃⌥;
            "maximizeWindowComboKey": combo(126, 1_310_720),         // ⌃⌘↑
            "launchAtLogin": NSNumber(value: true),
        ])
        #expect(result.shortcuts[.left] == KeyboardShortcut(
            keyCode: K.left, modifiers: KeyboardShortcut.controlFlag | KeyboardShortcut.commandFlag))
        #expect(result.shortcuts[.topRight] == KeyboardShortcut(keyCode: K.e, modifiers: ctrlOpt))
        #expect(result.shortcuts[.leftTwoThirds] == KeyboardShortcut(keyCode: 41, modifiers: ctrlOpt))
        #expect(result.shortcuts[.maximize] == KeyboardShortcut(
            keyCode: K.up, modifiers: KeyboardShortcut.controlFlag | KeyboardShortcut.commandFlag))
        #expect(result.unmapped.isEmpty)
    }

    @Test func absentKeysFollowMagnetsFactoryShortcuts() {
        let result = MagnetShortcuts.parse([:])
        #expect(result.shortcuts[.right] == KeyboardShortcut(keyCode: K.right, modifiers: ctrlOpt))
        #expect(result.shortcuts[.bottomLeft] == KeyboardShortcut(keyCode: K.j, modifiers: ctrlOpt))
        #expect(result.shortcuts[.centerThird] == KeyboardShortcut(keyCode: K.f, modifiers: ctrlOpt))
        #expect(result.shortcuts[.restore] == KeyboardShortcut(keyCode: K.delete, modifiers: ctrlOpt))
        // Magnet's display shortcuts are not read: Fenestra keeps its own.
        #expect(result.shortcuts[.nextDisplay] == nil)
        #expect(result.shortcuts[.previousDisplay] == nil)
    }

    @Test func reportsComboKeysWithoutEquivalent() {
        let result = MagnetShortcuts.parse([
            "centerWindowComboKey": combo(8, 786_432),
            "restoreWindowComboKey": [String: Any](),
        ])
        #expect(result.unmapped == ["centerWindow"])
        #expect(result.cleared == [.restore])
    }
}

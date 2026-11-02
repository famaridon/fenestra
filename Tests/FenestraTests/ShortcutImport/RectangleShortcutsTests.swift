import Foundation
import Testing
@testable import Fenestra

struct RectangleShortcutsTests {
    private typealias K = KeyboardShortcut.Key
    private let ctrlOpt = KeyboardShortcut.controlFlag | KeyboardShortcut.optionFlag
    private let cmdOpt = KeyboardShortcut.commandFlag | KeyboardShortcut.optionFlag

    /// As `defaults read com.knollsoft.Rectangle` shows them: `{ keyCode = 123; modifierFlags = 786432; }`.
    private func combo(_ keyCode: Int, _ flags: UInt) -> [String: Any] {
        ["keyCode": NSNumber(value: keyCode), "modifierFlags": NSNumber(value: flags)]
    }

    @Test func readsTheShortcutsTheUserSet() {
        let result = RectangleShortcuts.parse([
            "leftHalf": combo(123, 786_432),            // ⌃⌥←
            "topLeft": combo(32, 1_572_864),            // ⌥⌘U
            "firstThird": combo(2, 786_432),            // ⌃⌥D
            "alternateDefaultShortcuts": NSNumber(value: true),
        ])
        #expect(result.shortcuts[.left] == KeyboardShortcut(keyCode: K.left, modifiers: ctrlOpt))
        #expect(result.shortcuts[.topLeft] == KeyboardShortcut(keyCode: K.u, modifiers: cmdOpt))
        #expect(result.shortcuts[.leftThird] == KeyboardShortcut(keyCode: K.d, modifiers: ctrlOpt))
    }

    @Test func absentKeysFollowTheRecommendedDefaultsWhenRectangleUsesThem() {
        let result = RectangleShortcuts.parse(["alternateDefaultShortcuts": NSNumber(value: true)])
        #expect(result.shortcuts[.right] == KeyboardShortcut(keyCode: K.right, modifiers: ctrlOpt))
        #expect(result.shortcuts[.maximize] == KeyboardShortcut(keyCode: K.returnKey, modifiers: ctrlOpt))
        #expect(result.shortcuts[.rightThird] == KeyboardShortcut(keyCode: K.g, modifiers: ctrlOpt))
        #expect(result.shortcuts[.nextDisplay] == SnapAction.nextDisplay.defaultShortcut)
        #expect(result.shortcuts.count == SnapAction.allCases.count)
        #expect(result.cleared.isEmpty)
    }

    @Test func absentKeysFollowTheSpectacleDefaultsOtherwise() {
        let result = RectangleShortcuts.parse([:])
        #expect(result.shortcuts[.left] == KeyboardShortcut(keyCode: K.left, modifiers: cmdOpt))
        #expect(result.shortcuts[.maximize] == KeyboardShortcut(keyCode: K.f, modifiers: cmdOpt))
        #expect(result.shortcuts[.topLeft] == KeyboardShortcut(
            keyCode: K.left, modifiers: KeyboardShortcut.controlFlag | KeyboardShortcut.commandFlag))
        #expect(result.shortcuts[.leftThird] == nil)
        #expect(result.shortcuts[.restore] == KeyboardShortcut(keyCode: K.delete, modifiers: ctrlOpt))
    }

    @Test func anEmptyDictionaryMeansTheUserRemovedTheShortcut() {
        let result = RectangleShortcuts.parse(["restore": [String: Any](), "alternateDefaultShortcuts": NSNumber(value: true)])
        #expect(result.shortcuts[.restore] == nil)
        #expect(result.cleared == [.restore])
    }

    @Test func reportsActionsWithoutEquivalentAndSkipsMalformedValues() {
        let result = RectangleShortcuts.parse([
            "center": combo(8, 786_432),
            "larger": combo(24, 786_432),
            "leftHalf": combo(123, 0),                  // no modifier: not a global shortcut
            "maximize": "garbage",
            "SUEnableAutomaticChecks": NSNumber(value: true),
            "NSWindow Frame Settings": "0 0 100 100",
        ])
        #expect(result.unmapped == ["center", "larger"])
        #expect(result.shortcuts[.left] == nil)
        #expect(result.shortcuts[.maximize] == nil)
        #expect(result.cleared.isEmpty)
    }
}

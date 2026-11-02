import Foundation
import Testing
@testable import Fenestra

@MainActor
struct ShortcutImportUseCaseTests {
    private typealias K = KeyboardShortcut.Key
    let reader = FakeShortcutSourceReader()
    let store = FakeShortcutsStore()

    private func combo(_ keyCode: Int, _ flags: UInt) -> [String: Any] {
        ["keyCode": NSNumber(value: keyCode), "modifierFlags": NSNumber(value: flags)]
    }

    @Test func detectsOnlyTheSourcesInUse() {
        #expect(DetectShortcutSources(reader: reader).execute().isEmpty)
        reader.preferences[.magnet] = ["launchAtLogin": NSNumber(value: true)]
        reader.files[.aerospace] = "[mode.main.binding]\n"
        #expect(DetectShortcutSources(reader: reader).execute() == [.magnet, .aerospace])
    }

    @Test func importsIntoTheStoreAndReportsWhatHappened() {
        reader.preferences[.rectangle] = [
            "alternateDefaultShortcuts": NSNumber(value: true),
            "topLeft": combo(126, 1_310_720), // ⌃⌘↑ instead of ⌃⌥U
            "restore": [String: Any](),       // removed
            "center": combo(8, 786_432),      // no equivalent
        ]
        let imported = ImportShortcuts(reader: reader, store: store).execute(from: .rectangle)

        let ctrlCmd = KeyboardShortcut.controlFlag | KeyboardShortcut.commandFlag
        #expect(imported?.shortcuts[.topLeft] == KeyboardShortcut(keyCode: K.up, modifiers: ctrlCmd))
        #expect(imported?.cleared == [.restore])
        #expect(imported?.unmapped == ["center"])
        #expect(store.shortcuts[.topLeft] == KeyboardShortcut(keyCode: K.up, modifiers: ctrlCmd))
        #expect(store.shortcuts[.restore] == nil)
        #expect(store.shortcuts[.left] == SnapAction.left.defaultShortcut)
        #expect(store.shortcuts[.leftThird] == KeyboardShortcut(
            keyCode: K.d, modifiers: KeyboardShortcut.controlFlag | KeyboardShortcut.optionFlag))
    }

    @Test func aSourceNotInUseChangesNothing() {
        let before = store.shortcuts
        #expect(ImportShortcuts(reader: reader, store: store).execute(from: .aerospace) == nil)
        #expect(store.shortcuts == before)
    }

    @Test func mergeKeepsUnknownActionsAndFreesTakenShortcuts() {
        let ctrlOpt = KeyboardShortcut.controlFlag | KeyboardShortcut.optionFlag
        var imported = ImportedShortcuts()
        // AeroSpace: ⌃⌥↩ now goes full screen… which is already Fenestra's default for maximize,
        // and ⌃⌥← now moves to the previous display, taken from the `left` action.
        imported.shortcuts = [
            .maximize: KeyboardShortcut(keyCode: K.returnKey, modifiers: ctrlOpt),
            .previousDisplay: KeyboardShortcut(keyCode: K.left, modifiers: ctrlOpt),
        ]
        let merged = imported.merged(into: SnapAction.defaultShortcuts)

        #expect(merged[.maximize] == KeyboardShortcut(keyCode: K.returnKey, modifiers: ctrlOpt))
        #expect(merged[.previousDisplay] == KeyboardShortcut(keyCode: K.left, modifiers: ctrlOpt))
        #expect(merged[.left] == nil)
        #expect(merged[.right] == SnapAction.right.defaultShortcut)
        #expect(merged[.nextDisplay] == SnapAction.nextDisplay.defaultShortcut)
        #expect(merged.count == SnapAction.defaultShortcuts.count - 1)
    }
}

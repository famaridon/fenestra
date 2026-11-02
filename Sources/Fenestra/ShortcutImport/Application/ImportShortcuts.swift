import os

/// Takes over the shortcuts of another window manager: reads them, maps them to Fenestra's actions and
/// merges them into the settings (see `ImportedShortcuts.merged(into:)`).
@MainActor
final class ImportShortcuts {
    private let reader: any ShortcutSourceReader
    private let store: any ShortcutsStore
    private static let logger = Logger(subsystem: "com.florentamaridon.Fenestra", category: "shortcut-import")

    init(reader: any ShortcutSourceReader, store: any ShortcutsStore) {
        self.reader = reader
        self.store = store
    }

    /// What was imported, or nil when the source is not in use on this Mac (nothing changes then).
    @discardableResult
    func execute(from source: ShortcutSource) -> ImportedShortcuts? {
        guard let data = reader.read(source) else { return nil }
        let imported = source.parse(data)
        store.shortcuts = imported.merged(into: store.shortcuts)
        Self.logger.info("""
            \(source.name, privacy: .public): \(imported.shortcuts.count) shortcuts imported, \
            \(imported.cleared.count) cleared, \(imported.unmapped.count) without equivalent
            """)
        for binding in imported.unmapped {
            Self.logger.debug("no equivalent for \(binding, privacy: .public)")
        }
        return imported
    }
}

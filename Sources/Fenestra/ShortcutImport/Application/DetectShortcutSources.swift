/// Which other window managers are in use on this Mac, so Fenestra can offer to take over their shortcuts.
@MainActor
final class DetectShortcutSources {
    private let reader: any ShortcutSourceReader

    init(reader: any ShortcutSourceReader) {
        self.reader = reader
    }

    /// The sources that left preferences or a configuration file, in `ShortcutSource.allCases` order.
    func execute() -> [ShortcutSource] {
        ShortcutSource.allCases.filter { reader.read($0) != nil }
    }
}

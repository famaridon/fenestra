import Foundation

/// Reads what another window manager left on this Mac: its preferences or its configuration file.
@MainActor
protocol ShortcutSourceReader: AnyObject {
    /// nil when the app never wrote its preferences or has no configuration file: it is not in use here.
    func read(_ source: ShortcutSource) -> ShortcutSourceData?
}

/// Where the shortcuts live (the settings).
@MainActor
protocol ShortcutsStore: AnyObject {
    var shortcuts: [SnapAction: KeyboardShortcut] { get set }
}

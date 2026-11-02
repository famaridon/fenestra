import SwiftUI

/// Offers to take over the shortcuts of the window managers found on this Mac (`DetectShortcutSources`).
/// Used by the welcome window and the Shortcuts tab, which show it only when `sources` is not empty.
struct ShortcutImportView: View {
    let sources: [ShortcutSource]
    let importShortcuts: ImportShortcuts
    @State private var outcome: (source: ShortcutSource, imported: ImportedShortcuts)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Fenestra can reuse the shortcuts of the window managers found on this Mac.")
                .font(.callout)
                .foregroundStyle(.secondary)
            HStack {
                ForEach(sources) { source in
                    Button("Import from \(source.name)") {
                        if let imported = importShortcuts.execute(from: source) {
                            outcome = (source, imported)
                        }
                    }
                }
            }
            if let outcome {
                Text("^[\(outcome.imported.shortcuts.count) shortcut](inflect: true) imported from \(outcome.source.name).")
                    .font(.caption)
                if !outcome.imported.unmapped.isEmpty {
                    Text("^[\(outcome.imported.unmapped.count) binding](inflect: true) without equivalent in Fenestra (listed in the log).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

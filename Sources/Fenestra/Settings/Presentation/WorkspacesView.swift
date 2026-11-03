import SwiftUI

/// Workspaces tab: the saved arrangements, with their name, shortcut and the buttons to save, update,
/// apply and delete them.
struct WorkspacesView: View {
    let workspaces: WorkspaceCollection
    let navigation: SettingsNavigation
    let displays: any DisplayProvider
    let saveWorkspace: SaveWorkspace
    let applyWorkspace: ApplyWorkspace
    @State private var selection: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("A workspace brings back an arrangement of windows: from this list, the menu bar, a shortcut, or the fenestra tool.")
                .font(.callout)
                .foregroundStyle(.secondary)
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 6) {
                    List(workspaces.all, selection: $selection) { workspace in
                        HStack {
                            Text(verbatim: workspace.name)
                            Spacer()
                            if let shortcut = workspace.shortcut {
                                Text(verbatim: shortcut.displayString).foregroundStyle(.secondary)
                            }
                        }
                    }
                    HStack {
                        Button {
                            let saved = saveWorkspace.execute(name: WorkspaceLibrary.defaultName)
                            selection = saved.id
                        } label: { Image(systemName: "plus") }
                        .help("Save the current arrangement as a new workspace")
                        Button {
                            if let selection { workspaces.remove(id: selection) }
                            selection = nil
                        } label: { Image(systemName: "minus") }
                        .disabled(selection == nil)
                        Spacer()
                    }
                }
                .frame(width: 200)
                if let selected = selection.flatMap({ workspaces.workspace(id: $0) }) {
                    WorkspaceDetail(workspace: selected, workspaces: workspaces, displays: displays,
                                    saveWorkspace: saveWorkspace, applyWorkspace: applyWorkspace)
                } else {
                    Text("Select a workspace, or save the current arrangement with +.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .padding()
        .onAppear {
            if let wanted = navigation.workspace {
                selection = wanted
                navigation.workspace = nil
            } else if selection == nil {
                selection = workspaces.all.first?.id
            }
        }
    }
}

private struct WorkspaceDetail: View {
    let workspace: Workspace
    let workspaces: WorkspaceCollection
    let displays: any DisplayProvider
    let saveWorkspace: SaveWorkspace
    let applyWorkspace: ApplyWorkspace
    @State private var name: String = ""
    @State private var report: ControlResults.LayoutReport?
    @FocusState private var editingName: Bool

    var body: some View {
        Form {
            LabeledContent("Name") {
                HStack {
                    TextField("Name", text: $name, prompt: Text("Workspace name"))
                        .labelsHidden()
                        .focused($editingName)
                        .onSubmit { rename() }
                        // Leaving the field (a click elsewhere, Tab) keeps what was typed.
                        .onChange(of: editingName) { _, focused in if !focused { rename() } }
                    Button("Rename") { rename() }
                        .disabled(name.trimmingCharacters(in: .whitespaces) == workspace.name)
                }
            }
            LabeledContent("Shortcut") {
                ShortcutRecorderView(shortcut: Binding(
                    get: { workspace.shortcut },
                    set: { newValue in
                        var updated = workspace
                        updated.shortcut = newValue
                        workspaces.upsert(updated)
                    }
                ))
            }
            LabeledContent("Windows") {
                Text("^[\(workspace.layout.placements.count) window](inflect: true)")
            }
            Toggle("Apply automatically when these displays are connected", isOn: Binding(
                get: { workspace.displays != nil },
                set: { isOn in
                    var updated = workspace
                    updated.displays = isOn ? DisplaySignature(displays.currentLayout()) : nil
                    workspaces.upsert(updated)
                }
            ))
            Text("Displays: \(Self.describe(workspace.displays ?? DisplaySignature(displays.currentLayout())))")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Button("Apply") {
                    Task {
                        report = await applyWorkspace.execute(workspace)
                    }
                }
                Button("Update with Current Arrangement") {
                    saveWorkspace.execute(name: workspace.name)
                    report = nil
                }
            }
            if let report, !report.failed.isEmpty {
                Text("^[\(report.failed.count) window](inflect: true) could not be placed: \(report.failed.map { "\($0.app) (\($0.reason))" }.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear { name = workspace.name }
        .onChange(of: workspace.id) { name = workspace.name }
    }

    private func rename() {
        var updated = workspace
        updated.name = name
        workspaces.upsert(updated)
        name = workspaces.workspace(id: workspace.id)?.name ?? name
    }

    /// "1920 × 1080, 1080 × 1920"
    private static func describe(_ signature: DisplaySignature) -> String {
        signature.sizes.map { "\(Int($0.width)) × \(Int($0.height))" }.joined(separator: ", ")
    }
}

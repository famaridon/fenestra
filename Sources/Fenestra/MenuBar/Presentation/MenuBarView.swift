import SwiftUI

/// Content of the menu-bar extra.
struct MenuBarView: View {
    let settings: Settings
    let permission: AccessibilityPermission
    let navigation: SettingsNavigation
    let workspaces: WorkspaceCollection
    let saveWorkspace: SaveWorkspace
    let applyWorkspace: ApplyWorkspace
    /// Applies a snap action to the frontmost window.
    let perform: (SnapAction) -> Void
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        @Bindable var settings = settings
        if permission.isGranted {
            Text("Accessibility granted")
        } else {
            Text("Accessibility not granted")
            Button("Grant Access…") { permission.request() }
        }
        Divider()
        Toggle("Enable Fenestra", isOn: $settings.isEnabled)
        Menu("Arrange Window") {
            ForEach(SnapAction.allCases) { action in
                Button {
                    perform(action)
                } label: {
                    if let shortcut = settings.shortcuts[action] {
                        Text(verbatim: "\(action.localizedName)  \(shortcut.displayString)")
                    } else {
                        Text(action.localizedName)
                    }
                }
            }
        }
        Menu("Workspaces") {
            ForEach(workspaces.all) { workspace in
                Button {
                    Task { await applyWorkspace.execute(workspace) }
                } label: {
                    if let shortcut = workspace.shortcut {
                        Text(verbatim: "\(workspace.name)  \(shortcut.displayString)")
                    } else {
                        Text(verbatim: workspace.name)
                    }
                }
            }
            if !workspaces.all.isEmpty { Divider() }
            Button("Save Current Arrangement…") {
                let saved = saveWorkspace.execute(name: WorkspaceLibrary.defaultName)
                navigation.workspace = saved.id
                open(.workspaces)
            }
        }
        Divider()
        Button("Settings…") { open(nil) }
            .keyboardShortcut(",")
        Button("Quit Fenestra") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }

    /// Opens the settings window, on `tab` or on the last tab shown.
    private func open(_ tab: SettingsTab?) {
        if let tab { navigation.tab = tab }
        NSApplication.shared.activate()
        openSettings()
    }
}

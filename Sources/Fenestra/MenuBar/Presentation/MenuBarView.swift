import SwiftUI

/// Content of the menu-bar extra.
struct MenuBarView: View {
    let settings: Settings
    let permission: AccessibilityPermission
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
        Divider()
        Button("Settings…") {
            NSApplication.shared.activate()
            openSettings()
        }
        .keyboardShortcut(",")
        Button("Quit Fenestra") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }
}

import SwiftUI

/// Content of the menu-bar extra.
struct MenuBarView: View {
    @Environment(AppController.self) private var controller
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        @Bindable var settings = controller.settings
        if controller.permission.isGranted {
            Text("Accessibility granted")
        } else {
            Text("Accessibility not granted")
            Button("Grant Access…") { controller.permission.request() }
        }
        Divider()
        Toggle("Enable Fenestra", isOn: $settings.isEnabled)
        Menu("Arrange Window") {
            ForEach(SnapAction.allCases) { action in
                Button {
                    controller.perform(action)
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

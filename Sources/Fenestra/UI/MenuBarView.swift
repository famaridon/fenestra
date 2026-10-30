import SwiftUI

/// Content of the menu-bar extra.
struct MenuBarView: View {
    @Environment(AppController.self) private var controller
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        @Bindable var settings = controller.settings
        if controller.permission.isGranted {
            Text("Accessibilité autorisée")
        } else {
            Text("Accessibilité non autorisée")
            Button("Autoriser l'accès…") { controller.permission.request() }
        }
        Divider()
        Toggle("Activer Fenestra", isOn: $settings.isEnabled)
        Menu("Disposer la fenêtre") {
            ForEach(SnapAction.allCases) { action in
                Button {
                    controller.perform(action)
                } label: {
                    if let shortcut = settings.shortcuts[action] {
                        Text("\(action.localizedName)  \(shortcut.displayString)")
                    } else {
                        Text(action.localizedName)
                    }
                }
            }
        }
        Divider()
        Button("Réglages…") {
            NSApplication.shared.activate()
            openSettings()
        }
        .keyboardShortcut(",")
        Button("Quitter Fenestra") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }
}

import SwiftUI

@main
struct PanesApp: App {
    @State private var permission = AccessibilityPermission()

    var body: some Scene {
        MenuBarExtra("Panes", systemImage: "rectangle.split.2x1") {
            if permission.isGranted {
                Text("Accessibilité : autorisée")
            } else {
                Text("Accessibilité : non autorisée")
                Button("Autoriser l'accès…") { permission.request() }
            }
            Divider()
            Button("Quitter Panes") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}

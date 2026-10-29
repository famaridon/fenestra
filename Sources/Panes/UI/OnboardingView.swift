import SwiftUI

/// Welcome window: guides the user through granting the Accessibility permission.
struct OnboardingView: View {
    @Environment(AppController.self) private var controller
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        let granted = controller.permission.isGranted
        VStack(alignment: .leading, spacing: 16) {
            Label("Panes", systemImage: "rectangle.split.2x1")
                .font(.largeTitle.bold())
            VStack(alignment: .leading, spacing: 8) {
                Text("1. Ouvrez les Réglages Système et autorisez Panes dans Accessibilité.")
                Text("2. Glissez une fenêtre vers un bord ou un coin de l'écran.")
                Text("3. Relâchez : la fenêtre se place dans la zone affichée.")
            }
            Label(granted ? "Accessibilité autorisée" : "Accessibilité non autorisée",
                  systemImage: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(granted ? .green : .red)
            Button("Ouvrir les Réglages Système…") { controller.permission.request() }
                .disabled(granted)
            Text("Recommandé : désactivez le placement natif de macOS dans Réglages Système > Bureau et Dock > Fenêtres.")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            HStack {
                Spacer()
                Button("Terminer") {
                    controller.settings.hasCompletedOnboarding = true
                    controller.refresh()
                    dismissWindow(id: "onboarding")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!granted)
            }
        }
        .padding(24)
        .frame(width: 420, height: 380)
    }
}

import SwiftUI

/// Welcome window: guides the user through granting the Accessibility permission.
/// `ShortcutImport`: the block offering to reuse another window manager's shortcuts, built by the
/// composition root; nil when no such app is in use.
struct OnboardingView<ShortcutImport: View>: View {
    let settings: Settings
    let permission: AccessibilityPermission
    let shortcutImport: ShortcutImport?
    /// Called once the user is done (the monitors may start).
    let onDone: () -> Void
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        let granted = permission.isGranted
        VStack(alignment: .leading, spacing: 16) {
            Label("Fenestra", systemImage: "rectangle.split.2x1")
                .font(.largeTitle.bold())
            VStack(alignment: .leading, spacing: 8) {
                Text("1. Open System Settings and allow Fenestra under Accessibility.")
                Text("2. Drag a window to an edge or a corner of the screen.")
                Text("3. Release it: the window fills the highlighted zone.")
            }
            Label(granted ? "Accessibility granted" : "Accessibility not granted",
                  systemImage: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(granted ? .green : .red)
            Button("Open System Settings…") { permission.request() }
                .disabled(granted)
            Text("Recommended: turn off the built-in macOS tiling in System Settings > Desktop & Dock > Windows.")
                .font(.callout)
                .foregroundStyle(.secondary)
            if let shortcutImport {
                shortcutImport
            }
            Spacer()
            HStack {
                Spacer()
                Button("Done") {
                    settings.hasCompletedOnboarding = true
                    onDone()
                    dismissWindow(id: "onboarding")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!granted)
            }
        }
        .padding(24)
        .frame(width: 420, height: shortcutImport == nil ? 380 : 470)
    }
}

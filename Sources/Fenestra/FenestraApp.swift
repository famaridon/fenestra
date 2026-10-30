import SwiftUI

@main
struct FenestraApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var controller = AppController()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(controller)
        } label: {
            MenuBarIcon()
                .environment(controller)
        }
        .menuBarExtraStyle(.menu)

        SwiftUI.Settings {
            SettingsView()
                .environment(controller)
        }

        Window("Bienvenue dans Fenestra", id: "onboarding") {
            OnboardingView()
                .environment(controller)
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
    }
}

/// Menu-bar icon. It is alive from launch, so it also opens the welcome window when needed.
private struct MenuBarIcon: View {
    @Environment(AppController.self) private var controller
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Image("MenuBarIcon")
            .task {
                if controller.wantsOnboarding { openWindow(id: "onboarding") }
            }
            .onReceive(NotificationCenter.default.publisher(for: .fenestraShowOnboarding)) { _ in
                openWindow(id: "onboarding")
            }
    }
}

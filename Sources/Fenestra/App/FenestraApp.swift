import SwiftUI

@main
struct FenestraApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var controller = AppController()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(settings: controller.settings, permission: controller.permission,
                        navigation: controller.navigation, workspaces: controller.workspaces,
                        saveWorkspace: controller.saveWorkspace, applyWorkspace: controller.applyWorkspace,
                        perform: { controller.perform($0) })
        } label: {
            MenuBarIcon()
                .environment(controller)
        }
        .menuBarExtraStyle(.menu)

        SwiftUI.Settings {
            SettingsView(settings: controller.settings, navigation: controller.navigation,
                         loginItem: controller.loginItem, screenRecording: controller.screenRecording,
                         shortcutImport: shortcutImport, workspaces: controller.workspaces,
                         displays: controller.displays, saveWorkspace: controller.saveWorkspace,
                         applyWorkspace: controller.applyWorkspace)
        }

        Window("Welcome to Fenestra", id: "onboarding") {
            OnboardingView(settings: controller.settings, permission: controller.permission,
                           shortcutImport: shortcutImport, onDone: { controller.refresh() })
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
    }

    /// Offer to reuse the shortcuts of Rectangle, Magnet or AeroSpace; nil when none is in use on this Mac.
    /// Looked up when a window is built, so a newly installed app shows up at the next opening.
    private var shortcutImport: ShortcutImportView? {
        let sources = controller.detectShortcutSources.execute()
        return sources.isEmpty ? nil : ShortcutImportView(sources: sources, importShortcuts: controller.importShortcuts)
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

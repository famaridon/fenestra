import Foundation
import Observation

/// Tabs of the settings window.
enum SettingsTab: String, Sendable {
    case general, zones, shortcuts, exclusions, workspaces, agents, about
}

/// Where the settings window should open: the menu sets it, the window follows. Not persisted.
@MainActor
@Observable
final class SettingsNavigation {
    var tab: SettingsTab = .general
    /// Workspace to select in the Workspaces tab, when the menu just created one.
    var workspace: UUID?
}

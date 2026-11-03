/// Where the workspaces are kept between launches (a JSON file).
@MainActor
protocol WorkspaceStore: AnyObject {
    /// Empty when nothing was saved yet.
    func load() throws -> [Workspace]
    func save(_ workspaces: [Workspace]) throws
}

/// The stacking order of the windows on screen (the window server knows it, the Accessibility API does not).
@MainActor
protocol WindowStacking: AnyObject {
    /// Every on-screen window, front to back.
    func frontToBack() -> [StackedWindow]
}

/// A workspace as the `fenestra` tool lists it.
struct WorkspaceSummary: Codable, Sendable, Equatable {
    var name: String
    var windows: Int
    var shortcut: String?
    var automatic: Bool
}

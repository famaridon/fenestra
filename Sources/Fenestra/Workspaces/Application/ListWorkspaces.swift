/// `list_workspaces`: the saved workspaces, in their order.
@MainActor
final class ListWorkspaces {
    private let workspaces: WorkspaceCollection

    init(workspaces: WorkspaceCollection) {
        self.workspaces = workspaces
    }

    func execute() -> [WorkspaceSummary] {
        workspaces.all.map {
            WorkspaceSummary(name: $0.name, windows: $0.layout.placements.count,
                             shortcut: $0.shortcut?.displayString, automatic: $0.displays != nil)
        }
    }
}

/// `delete_workspace`.
@MainActor
final class DeleteWorkspace {
    private let workspaces: WorkspaceCollection

    init(workspaces: WorkspaceCollection) {
        self.workspaces = workspaces
    }

    func execute(named name: String) throws {
        guard let workspace = workspaces.workspace(named: name) else { throw ApplyWorkspace.UnknownWorkspace(name: name) }
        workspaces.remove(id: workspace.id)
    }
}

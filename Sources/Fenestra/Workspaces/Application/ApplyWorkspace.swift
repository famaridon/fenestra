/// Applies a saved workspace: its layout, adapted to the displays connected now, through `ApplyLayout`.
@MainActor
final class ApplyWorkspace {
    struct UnknownWorkspace: Error, CustomStringConvertible {
        let name: String
        var description: String { "no workspace named \"\(name)\"" }
    }

    private let workspaces: WorkspaceCollection
    private let displays: any DisplayProvider
    private let applyLayout: ApplyLayout

    init(workspaces: WorkspaceCollection, displays: any DisplayProvider, applyLayout: ApplyLayout) {
        self.workspaces = workspaces
        self.displays = displays
        self.applyLayout = applyLayout
    }

    /// `launchApps`: open the apps that have no window (a manual restore); false for an automatic one.
    func execute(named name: String, launchApps: Bool = true) async throws -> ControlResults.LayoutReport {
        guard let workspace = workspaces.workspace(named: name) else { throw UnknownWorkspace(name: name) }
        return await execute(workspace, launchApps: launchApps)
    }

    func execute(_ workspace: Workspace, launchApps: Bool = true) async -> ControlResults.LayoutReport {
        let layout = WorkspaceLibrary.layout(of: workspace, for: displays.currentLayout(), launchApps: launchApps)
        return await applyLayout.execute(layout)
    }
}

import os

/// After the display configuration changed: applies the workspace saved for the displays now connected,
/// without launching apps. Nothing happens while the configuration stays the same (sleep, wake…) or at launch.
@MainActor
final class ApplyWorkspaceForDisplays {
    private let workspaces: WorkspaceCollection
    private let displays: any DisplayProvider
    private let applyWorkspace: ApplyWorkspace
    private var lastSignature: DisplaySignature
    private static let logger = Logger(subsystem: "com.florentamaridon.Fenestra", category: "workspaces")

    init(workspaces: WorkspaceCollection, displays: any DisplayProvider, applyWorkspace: ApplyWorkspace) {
        self.workspaces = workspaces
        self.displays = displays
        self.applyWorkspace = applyWorkspace
        lastSignature = DisplaySignature(displays.currentLayout())
    }

    /// The workspace applied, if any.
    @discardableResult
    func execute() async -> Workspace? {
        let layout = displays.currentLayout()
        let signature = DisplaySignature(layout)
        guard signature != lastSignature else { return nil }
        lastSignature = signature
        guard let workspace = workspaces.all.first(where: { $0.displays?.matches(layout) == true }) else { return nil }
        Self.logger.info("displays changed: applying workspace \(workspace.name, privacy: .public)")
        _ = await applyWorkspace.execute(workspace, launchApps: false)
        return workspace
    }
}

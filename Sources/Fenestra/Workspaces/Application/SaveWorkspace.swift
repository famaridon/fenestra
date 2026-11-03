/// Saves a workspace: the windows on screen as they are, or a layout given by an agent. A workspace
/// with that name is updated (it keeps its id, shortcut and displays); otherwise one is created.
@MainActor
final class SaveWorkspace {
    private let workspaces: WorkspaceCollection
    private let manageable: ManageableWindows
    private let displays: any DisplayProvider
    private let store: SnapStore
    private let stacking: any WindowStacking
    private let settings: any SnapSettingsProvider

    init(workspaces: WorkspaceCollection, manageable: ManageableWindows, displays: any DisplayProvider,
         store: SnapStore, stacking: any WindowStacking, settings: any SnapSettingsProvider) {
        self.workspaces = workspaces
        self.manageable = manageable
        self.displays = displays
        self.store = store
        self.stacking = stacking
        self.settings = settings
    }

    @discardableResult
    func execute(name: String, layout: LayoutSpec? = nil) -> Workspace {
        let layout = layout ?? capture()
        var workspace = workspaces.workspace(named: name)
            ?? Workspace(name: name.trimmingCharacters(in: .whitespacesAndNewlines), layout: layout)
        workspace.layout = layout
        workspaces.upsert(workspace)
        return workspaces.workspace(id: workspace.id) ?? workspace
    }

    /// The manageable windows on screen, front to back, as placements (the first one comes back in front).
    func capture() -> LayoutSpec {
        let captured = manageable.all().compactMap { window -> CapturedWindow? in
            guard let frame = window.frame else { return nil }
            return CapturedWindow(bundleIdentifier: window.bundleIdentifier, appName: window.appName,
                                  title: window.title, frame: frame,
                                  zone: store.currentRecord(for: window, frame: frame)?.zone, pid: window.pid)
        }
        let ordered = WorkspaceCapture.sorted(captured, frontToBack: stacking.frontToBack())
        return WorkspaceCapture.layout(of: ordered, screens: displays.currentLayout(), gap: settings.snapSettings.gap)
    }
}

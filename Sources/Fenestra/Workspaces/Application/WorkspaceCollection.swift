import Foundation
import Observation
import os

/// The user's workspaces, loaded once and written back after each change (the menu, the settings and
/// the `fenestra` tool all read it).
@MainActor
@Observable
final class WorkspaceCollection {
    private(set) var all: [Workspace]
    @ObservationIgnored private let store: any WorkspaceStore
    private static let logger = Logger(subsystem: "com.florentamaridon.Fenestra", category: "workspaces")

    init(store: any WorkspaceStore) {
        self.store = store
        do {
            all = try store.load()
        } catch {
            Self.logger.error("cannot load the workspaces: \(error.localizedDescription, privacy: .public)")
            all = []
        }
    }

    func workspace(named name: String) -> Workspace? {
        WorkspaceLibrary.index(named: name, in: all).map { all[$0] }
    }

    func workspace(id: UUID) -> Workspace? {
        all.first { $0.id == id }
    }

    /// Adds the workspace, or replaces the one with the same id. The name is made unique among the others.
    func upsert(_ workspace: Workspace) {
        var workspace = workspace
        workspace.name = WorkspaceLibrary.uniqueName(workspace.name, among: all, excluding: workspace.id)
        if let index = all.firstIndex(where: { $0.id == workspace.id }) {
            all[index] = workspace
        } else {
            all.append(workspace)
        }
        persist()
    }

    func remove(id: UUID) {
        guard let index = all.firstIndex(where: { $0.id == id }) else { return }
        all.remove(at: index)
        persist()
    }

    private func persist() {
        do {
            try store.save(all)
        } catch {
            Self.logger.error("cannot save the workspaces: \(error.localizedDescription, privacy: .public)")
        }
    }
}

import Foundation

/// `WorkspaceStore` as a readable JSON file, `~/Library/Application Support/Fenestra/workspaces.json`
/// (next to the control socket), written atomically.
@MainActor
final class FileWorkspaceStore: WorkspaceStore {
    let url: URL

    init(url: URL = ControlSocket.url.deletingLastPathComponent().appendingPathComponent("workspaces.json")) {
        self.url = url
    }

    func load() throws -> [Workspace] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        return try JSONDecoder().decode([Workspace].self, from: Data(contentsOf: url))
    }

    func save(_ workspaces: [Workspace]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(workspaces).write(to: url, options: .atomic)
    }
}

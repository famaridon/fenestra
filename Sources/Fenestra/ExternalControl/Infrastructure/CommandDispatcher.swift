import Foundation
import os

private let log = Logger(subsystem: "com.florentamaridon.Fenestra", category: "commands")

/// Decodes a request of the control socket, runs the matching use case and encodes the reply line.
@MainActor
final class CommandDispatcher {
    struct CommandError: Error, CustomStringConvertible {
        var description: String
        init(_ description: String) { self.description = description }
    }

    /// Arguments of the workspace commands.
    private struct WorkspaceArguments: Decodable {
        var name: String
        var layout: LayoutSpec?
        var launchApps: Bool?

        enum CodingKeys: String, CodingKey {
            case name, layout
            case launchApps = "launch_apps"
        }
    }

    private struct Done: Encodable {
        var done = true
    }

    private let trust: any AccessibilityTrust
    private let settings: Settings
    private let listDisplays: ListDisplays
    private let listWindows: ListWindows
    private let applyLayout: ApplyLayout
    private let listWorkspaces: ListWorkspaces
    private let saveWorkspace: SaveWorkspace
    private let applyWorkspace: ApplyWorkspace
    private let deleteWorkspace: DeleteWorkspace

    init(trust: any AccessibilityTrust, settings: Settings, listDisplays: ListDisplays,
         listWindows: ListWindows, applyLayout: ApplyLayout, listWorkspaces: ListWorkspaces,
         saveWorkspace: SaveWorkspace, applyWorkspace: ApplyWorkspace, deleteWorkspace: DeleteWorkspace) {
        self.trust = trust
        self.settings = settings
        self.listDisplays = listDisplays
        self.listWindows = listWindows
        self.applyLayout = applyLayout
        self.listWorkspaces = listWorkspaces
        self.saveWorkspace = saveWorkspace
        self.applyWorkspace = applyWorkspace
        self.deleteWorkspace = deleteWorkspace
    }

    /// Handles one request (`{"command": ..., "arguments": {...}}`) and returns the reply line.
    func handle(_ request: Data) async -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        do {
            guard let object = try JSONSerialization.jsonObject(with: request) as? [String: Any],
                  let command = object["command"] as? String else {
                throw CommandError("expected {\"command\": ..., \"arguments\": {...}}")
            }
            let arguments = try JSONSerialization.data(withJSONObject: object["arguments"] ?? [String: Any]())
            let result = try await run(command, arguments: arguments)
            let payload = try JSONSerialization.jsonObject(with: encoder.encode(result))
            return try JSONSerialization.data(withJSONObject: ["ok": true, "result": payload])
        } catch {
            log.info("command failed: \(String(describing: error), privacy: .public)")
            let message = (error as? DecodingError).map(Self.describe) ?? String(describing: error)
            return (try? JSONSerialization.data(withJSONObject: ["ok": false, "error": message])) ?? Data()
        }
    }

    private func run(_ command: String, arguments: Data) async throws -> any Encodable {
        guard trust.isTrusted else {
            throw CommandError("Fenestra is not allowed to control windows: grant it Accessibility in System Settings")
        }
        guard settings.isEnabled else { throw CommandError("Fenestra is paused (menu bar switch)") }
        switch command {
        case "list_displays": return listDisplays.execute()
        case "list_windows": return listWindows.execute()
        case "apply_layout": return await applyLayout.execute(try JSONDecoder().decode(LayoutSpec.self, from: arguments))
        case "list_workspaces": return listWorkspaces.execute()
        case "save_workspace":
            let args = try workspaceArguments(arguments)
            return saveWorkspace.execute(name: args.name, layout: args.layout)
        case "apply_workspace":
            let args = try workspaceArguments(arguments)
            return try await applyWorkspace.execute(named: args.name, launchApps: args.launchApps ?? true)
        case "delete_workspace":
            try deleteWorkspace.execute(named: try workspaceArguments(arguments).name)
            return Done()
        default: throw CommandError("unknown command \"\(command)\"")
        }
    }

    private func workspaceArguments(_ data: Data) throws -> WorkspaceArguments {
        let args = try JSONDecoder().decode(WorkspaceArguments.self, from: data)
        guard !args.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CommandError("\"name\" must not be empty")
        }
        if let layout = args.layout, layout.placements.isEmpty { throw CommandError("\"layout\" needs at least one placement") }
        return args
    }

    private static func describe(_ error: DecodingError) -> String {
        switch error {
        case .keyNotFound(let key, let context):
            "missing \"\(key.stringValue)\" at \(path(context))"
        case .typeMismatch(_, let context), .valueNotFound(_, let context), .dataCorrupted(let context):
            "invalid value at \(path(context)): \(context.debugDescription)"
        @unknown default:
            String(describing: error)
        }
    }

    private static func path(_ context: DecodingError.Context) -> String {
        let path = context.codingPath.map { $0.intValue.map(String.init) ?? $0.stringValue }.joined(separator: ".")
        return path.isEmpty ? "top level" : path
    }
}

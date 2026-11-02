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

    private let trust: any AccessibilityTrust
    private let settings: Settings
    private let listDisplays: ListDisplays
    private let listWindows: ListWindows
    private let applyLayout: ApplyLayout

    init(trust: any AccessibilityTrust, settings: Settings, listDisplays: ListDisplays,
         listWindows: ListWindows, applyLayout: ApplyLayout) {
        self.trust = trust
        self.settings = settings
        self.listDisplays = listDisplays
        self.listWindows = listWindows
        self.applyLayout = applyLayout
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
        default: throw CommandError("unknown command \"\(command)\"")
        }
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

import AppKit
import os

private let log = Logger(subsystem: "com.florentamaridon.Fenestra", category: "commands")

/// Commands sent by the `fenestra` tool (and through it, AI agents over MCP).
@MainActor
final class CommandService {
    struct Rect: Codable, Sendable {
        var x: Double, y: Double, width: Double, height: Double
        init(_ r: CGRect) { x = r.minX; y = r.minY; width = r.width; height = r.height }
    }

    struct DisplayInfo: Codable, Sendable {
        var index: Int
        var id: UInt32
        var isPrimary: Bool
        var orientation: String
        var frame: Rect
        var visibleFrame: Rect
    }

    struct WindowInfo: Codable, Sendable {
        var app: String?
        var bundleIdentifier: String?
        var title: String?
        var display: Int?
        var zone: Zone?
        var frame: Rect?
    }

    struct PlacedWindow: Codable, Sendable {
        var placement: Int
        var app: String?
        var title: String?
        var display: Int
        var zone: Zone?
        var frame: Rect
    }

    struct FailedPlacement: Codable, Sendable {
        var placement: Int
        var app: String
        var reason: String
    }

    struct LayoutReport: Codable, Sendable {
        var placed: [PlacedWindow]
        var failed: [FailedPlacement]
    }

    struct CommandError: Error, CustomStringConvertible {
        var description: String
        init(_ description: String) { self.description = description }
    }

    private static let launchTimeout: Duration = .seconds(10)

    private let settings: Settings
    private let snapController: SnapController

    init(settings: Settings, snapController: SnapController) {
        self.settings = settings
        self.snapController = snapController
    }

    // MARK: Dispatch

    /// Handles one request of the control socket and returns the reply line.
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
        guard AccessibilityPermission.isTrusted else {
            throw CommandError("Fenestra is not allowed to control windows: grant it Accessibility in System Settings")
        }
        guard settings.isEnabled else { throw CommandError("Fenestra is paused (menu bar switch)") }
        switch command {
        case "list_displays": return listDisplays()
        case "list_windows": return listWindows()
        case "apply_layout": return await applyLayout(try JSONDecoder().decode(LayoutSpec.self, from: arguments))
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

    // MARK: Queries

    func listDisplays() -> [DisplayInfo] {
        let layout = ScreenLayout.current()
        let primary = layout.screen(matching: "primary")
        return layout.readingOrder.enumerated().map { offset, screen in
            DisplayInfo(index: offset + 1, id: screen.id, isPrimary: screen.id == primary?.id,
                        orientation: screen.orientation.rawValue,
                        frame: Rect(screen.frame), visibleFrame: Rect(screen.visibleFrame))
        }
    }

    /// Manageable windows, front-most first within each app.
    func listWindows() -> [WindowInfo] {
        let layout = ScreenLayout.current()
        return manageableWindows().map { window in
            let frame = window.frame
            let screen = frame.flatMap { layout.screen(for: $0) }
            let record = snapController.registry.record(for: window)
            let snapped = frame.map { snapController.registry.isStillSnapped(window, frame: $0, tolerance: 4) } ?? false
            return WindowInfo(app: window.appName, bundleIdentifier: window.bundleIdentifier, title: window.title,
                              display: screen.flatMap { displayIndex(of: $0, in: layout) },
                              zone: snapped ? record?.zone : nil, frame: frame.map(Rect.init))
        }
    }

    // MARK: Layout

    func applyLayout(_ spec: LayoutSpec) async -> LayoutReport {
        var windows = manageableWindows()
        if spec.launchApps == true {
            let missing = missingApps(spec, windows: windows)
            if !missing.isEmpty {
                await launch(missing)
                windows = await waitForWindows(spec)
            }
        }
        let layout = ScreenLayout.current()
        let plan = LayoutPlanner.plan(spec, windows: descriptors(windows), layout: layout, gap: CGFloat(settings.gap))
        var report = LayoutReport(placed: [], failed: [])
        var placedWindows: [AXWindow] = []
        for (index, result) in plan.enumerated() {
            let placement = spec.placements[index]
            switch result {
            case .failure(let issue):
                report.failed.append(FailedPlacement(placement: index, app: placement.app, reason: issue.description))
            case .success(let planned):
                let window = windows[planned.windowIndex]
                let actual: CGRect?
                if let zone = planned.zone {
                    snapController.placeExternal(window: window, zone: zone, screen: planned.screen)
                    actual = window.frame
                } else {
                    actual = snapController.placeCustom(window, frame: planned.frame)
                }
                guard let actual else {
                    report.failed.append(FailedPlacement(placement: index, app: placement.app,
                                                         reason: "the window refused to move"))
                    continue
                }
                placedWindows.append(window)
                report.placed.append(PlacedWindow(placement: index, app: window.appName, title: window.title,
                                                  display: displayIndex(of: planned.screen, in: layout) ?? 0,
                                                  zone: planned.zone, frame: Rect(actual)))
            }
        }
        // The first placement ends up in front.
        for window in placedWindows.reversed() { window.raise() }
        return report
    }

    private func manageableWindows() -> [AXWindow] {
        AXWindowFinder.visibleStandardWindows().filter(snapController.isManageable)
    }

    private func displayIndex(of screen: ScreenInfo, in layout: ScreenLayout) -> Int? {
        layout.readingOrder.firstIndex { $0.id == screen.id }.map { $0 + 1 }
    }

    // MARK: Launching apps

    private func descriptors(_ windows: [AXWindow]) -> [LayoutWindow] {
        windows.map { LayoutWindow(bundleIdentifier: $0.bundleIdentifier, appName: $0.appName, title: $0.title) }
    }

    /// Apps of the placements left without a window, without duplicates.
    private func missingApps(_ spec: LayoutSpec, windows: [AXWindow]) -> [String] {
        let assignment = LayoutPlanner.assign(spec.placements, to: descriptors(windows))
        var seen = Set<String>()
        return spec.placements.indices.compactMap { i in
            guard assignment[i] == nil else { return nil }
            let app = spec.placements[i].app
            return seen.insert(app.lowercased()).inserted ? app : nil
        }
    }

    private func launch(_ apps: [String]) async {
        for app in apps {
            guard let url = Self.applicationURL(for: app) else {
                log.info("no application found for \(app, privacy: .public)")
                continue
            }
            let configuration = NSWorkspace.OpenConfiguration()
            // Activation makes a running app without windows open one (reopen event).
            configuration.activates = true
            do {
                _ = try await NSWorkspace.shared.openApplication(at: url, configuration: configuration)
            } catch {
                log.info("could not open \(app, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// Polls until every placement has a window, or the timeout expires.
    private func waitForWindows(_ spec: LayoutSpec) async -> [AXWindow] {
        let deadline = ContinuousClock.now + Self.launchTimeout
        while true {
            let windows = manageableWindows()
            let complete = !LayoutPlanner.assign(spec.placements, to: descriptors(windows)).contains(nil)
            if complete || ContinuousClock.now >= deadline { return windows }
            try? await Task.sleep(for: .milliseconds(250))
        }
    }

    private static func applicationURL(for app: String) -> URL? {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app) { return url }
        let name = app.hasSuffix(".app") ? app : app + ".app"
        let folders = ["/Applications", "/Applications/Utilities", "/System/Applications",
                       "/System/Applications/Utilities", NSHomeDirectory() + "/Applications"]
        return folders.lazy
            .map { URL(fileURLWithPath: $0).appendingPathComponent(name) }
            .first { FileManager.default.fileExists(atPath: $0.path) }
    }
}

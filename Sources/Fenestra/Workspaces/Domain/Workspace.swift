import CoreGraphics
import Foundation

/// A named arrangement of windows: the `LayoutSpec` to apply, as the `fenestra` tool would send it.
struct Workspace: Codable, Sendable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var layout: LayoutSpec
    /// Global shortcut that applies the workspace.
    var shortcut: KeyboardShortcut?
    /// When set, the workspace is applied on its own as soon as the connected displays match.
    var displays: DisplaySignature?

    init(id: UUID = UUID(), name: String, layout: LayoutSpec, shortcut: KeyboardShortcut? = nil,
         displays: DisplaySignature? = nil) {
        self.id = id
        self.name = name
        self.layout = layout
        self.shortcut = shortcut
        self.displays = displays
    }

    /// Names compare trimmed and case-insensitively.
    func isNamed(_ name: String) -> Bool {
        Self.normalized(self.name) == Self.normalized(name)
    }

    static func normalized(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

/// What a set of displays looks like, independent of their ids (which change between connections):
/// the sizes of their frames, sorted.
struct DisplaySignature: Codable, Sendable, Equatable {
    struct Size: Codable, Sendable, Equatable, Comparable {
        var width: Double
        var height: Double
        static func < (lhs: Size, rhs: Size) -> Bool { (lhs.width, lhs.height) < (rhs.width, rhs.height) }
    }

    var sizes: [Size]

    init(_ layout: ScreenLayout) {
        sizes = layout.screens.map { Size(width: $0.frame.width, height: $0.frame.height) }.sorted()
    }

    func matches(_ layout: ScreenLayout) -> Bool {
        self == DisplaySignature(layout)
    }
}

/// Rules on a list of workspaces: names are unique (case-insensitive) and never empty.
enum WorkspaceLibrary {
    static let defaultName = "Workspace"

    /// `proposed`, trimmed, or "Workspace"; with " 2", " 3"… appended while another workspace has that name.
    static func uniqueName(_ proposed: String, among workspaces: [Workspace], excluding id: UUID? = nil) -> String {
        let trimmed = proposed.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? defaultName : trimmed
        let others = workspaces.filter { $0.id != id }
        var candidate = base
        var counter = 2
        while others.contains(where: { $0.isNamed(candidate) }) {
            candidate = "\(base) \(counter)"
            counter += 1
        }
        return candidate
    }

    static func index(named name: String, in workspaces: [Workspace]) -> Int? {
        workspaces.firstIndex { $0.isNamed(name) }
    }

    /// The layout to apply on the current displays: a placement whose display index no longer exists goes to
    /// the primary display instead of failing. `launchApps` is set as asked.
    static func layout(of workspace: Workspace, for screens: ScreenLayout, launchApps: Bool) -> LayoutSpec {
        var spec = workspace.layout
        spec.launchApps = launchApps
        for index in spec.placements.indices {
            guard let selector = spec.placements[index].display, screens.screen(matching: selector) == nil else { continue }
            spec.placements[index].display = nil
        }
        return spec
    }
}

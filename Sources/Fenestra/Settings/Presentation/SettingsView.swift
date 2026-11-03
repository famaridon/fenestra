import SwiftUI

/// Settings window with one tab per topic.
/// `ShortcutImport`: the block offering to reuse another window manager's shortcuts, built by the
/// composition root; nil when no such app is in use.
struct SettingsView<ShortcutImport: View>: View {
    let settings: Settings
    let navigation: SettingsNavigation
    let loginItem: any LoginItem
    let screenRecording: any ScreenRecordingAccess
    let shortcutImport: ShortcutImport?
    let workspaces: WorkspaceCollection
    let displays: any DisplayProvider
    let saveWorkspace: SaveWorkspace
    let applyWorkspace: ApplyWorkspace

    var body: some View {
        @Bindable var navigation = navigation
        TabView(selection: $navigation.tab) {
            GeneralTab(settings: settings, loginItem: loginItem, screenRecording: screenRecording)
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(SettingsTab.general)
            ZonesTab(settings: settings)
                .tabItem { Label("Zones", systemImage: "rectangle.split.2x2") }
                .tag(SettingsTab.zones)
            ShortcutsTab(settings: settings, shortcutImport: shortcutImport)
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
                .tag(SettingsTab.shortcuts)
            WorkspacesView(workspaces: workspaces, navigation: navigation, displays: displays,
                           saveWorkspace: saveWorkspace, applyWorkspace: applyWorkspace)
                .tabItem { Label("Workspaces", systemImage: "square.grid.2x2") }
                .tag(SettingsTab.workspaces)
            ExcludedAppsView(settings: settings)
                .tabItem { Label("Exclusions", systemImage: "nosign") }
                .tag(SettingsTab.exclusions)
            AgentsTab(settings: settings)
                .tabItem { Label("Agents", systemImage: "sparkles") }
                .tag(SettingsTab.agents)
            AboutTab()
                .tabItem { Label("About", systemImage: "info.circle") }
                .tag(SettingsTab.about)
        }
        .frame(width: 560, height: 460)
    }
}

private struct GeneralTab: View {
    @Bindable var settings: Settings
    let loginItem: any LoginItem
    let screenRecording: any ScreenRecordingAccess
    @State private var launchAtLogin: Bool
    @State private var launchError: String?
    @State private var screenRecordingGranted: Bool

    init(settings: Settings, loginItem: any LoginItem, screenRecording: any ScreenRecordingAccess) {
        self.settings = settings
        self.loginItem = loginItem
        self.screenRecording = screenRecording
        _launchAtLogin = State(initialValue: loginItem.isEnabled)
        _screenRecordingGranted = State(initialValue: screenRecording.isGranted)
    }

    var body: some View {
        Form {
            Toggle("Launch at login", isOn: Binding(
                get: { launchAtLogin },
                set: { newValue in
                    do {
                        try loginItem.set(newValue)
                        launchError = nil
                    } catch {
                        launchError = error.localizedDescription
                    }
                    launchAtLogin = loginItem.isEnabled
                }
            ))
            if let launchError {
                Text(launchError).font(.caption).foregroundStyle(.red)
            }
            Toggle("Snap windows by dragging them to an edge", isOn: $settings.dragSnapEnabled)
            Toggle("Restore original size when unsnapping", isOn: $settings.restoreOnUnsnap)
            Toggle("Shared border between snapped windows", isOn: $settings.sharedBorderEnabled)
            Toggle("Snap Layouts when hovering the green button", isOn: $settings.snapLayoutsEnabled)
            Toggle("Snap Assist", isOn: $settings.snapAssistEnabled)
            Toggle("Window previews in Snap Assist", isOn: Binding(
                get: { settings.snapAssistPreviews },
                set: { newValue in
                    settings.snapAssistPreviews = newValue
                    if newValue && !screenRecordingGranted {
                        screenRecordingGranted = screenRecording.request()
                    }
                }
            ))
            .disabled(!settings.snapAssistEnabled)
            if settings.snapAssistPreviews && !screenRecordingGranted {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Previews need the Screen & System Audio Recording permission. Without it, Snap Assist shows the app icons. Once the permission is granted, relaunch Fenestra if macOS asks you to.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Open System Settings") { screenRecording.openSystemSettings() }
                }
            }
            LabeledContent("Gap between windows: \(Int(settings.gap)) pt") {
                Slider(value: $settings.gap, in: 0...32, step: 1)
            }
            Stepper("Corner size: \(Int(settings.cornerLength)) pt",
                    value: $settings.cornerLength, in: 40...300, step: 10)
            LabeledContent("Trigger band between two displays: \(Int(settings.innerEdgeThreshold)) pt") {
                Slider(value: $settings.innerEdgeThreshold, in: 4...80, step: 2)
            }
            Text("The pointer stops on an outer edge, but crosses the junction between two displays, hence a wider band.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        // macOS doesn't notify permission changes: refresh whenever the tab is shown again.
        .onAppear { screenRecordingGranted = screenRecording.isGranted }
    }
}

private struct ZonesTab: View {
    @Bindable var settings: Settings

    private let groups: [(String, [Zone])] = [
        (String(localized: "Halves"), [.leftHalf, .rightHalf, .topHalf, .bottomHalf]),
        (String(localized: "Quarters"), [.topLeft, .topRight, .bottomLeft, .bottomRight]),
        (String(localized: "Full Screen"), [.maximize]),
        (String(localized: "Thirds"), [.leftThird, .centerThird, .rightThird, .leftTwoThirds, .rightTwoThirds]),
    ]

    var body: some View {
        Form {
            ForEach(groups, id: \.0) { title, zones in
                Section(title) {
                    ForEach(zones) { zone in
                        Toggle(isOn: binding(for: zone)) {
                            Label(zone.localizedName, systemImage: zone.systemImage)
                        }
                    }
                }
            }
            Section("Vertical Display") {
                Toggle("Top edge goes full screen", isOn: $settings.portraitTopEdgeMaximizes)
                Toggle("Left and right edges active", isOn: $settings.portraitSideEdgesEnabled)
                Toggle("With the keyboard, ← and → cut the top and bottom halves into quarters",
                       isOn: $settings.portraitArrowsSplitHalves)
            }
        }
        .formStyle(.grouped)
    }

    private func binding(for zone: Zone) -> Binding<Bool> {
        Binding(
            get: { settings.enabledZones.contains(zone) },
            set: { isOn in
                if isOn { settings.enabledZones.insert(zone) } else { settings.enabledZones.remove(zone) }
            }
        )
    }
}

private struct ShortcutsTab<ShortcutImport: View>: View {
    @Bindable var settings: Settings
    let shortcutImport: ShortcutImport?

    var body: some View {
        Form {
            ForEach(SnapAction.allCases) { action in
                LabeledContent(action.localizedName) {
                    ShortcutRecorderView(shortcut: Binding(
                        get: { settings.shortcuts[action] },
                        set: { settings.shortcuts[action] = $0 }
                    ))
                }
            }
            Button("Restore Default Shortcuts") { settings.resetShortcuts() }
            if let shortcutImport {
                Section("Import") { shortcutImport }
            }
        }
        .formStyle(.grouped)
    }
}

private struct AgentsTab: View {
    @Bindable var settings: Settings

    /// The `fenestra` tool of this copy of the app.
    private static var toolPath: String {
        Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/fenestra").path
    }

    private static var claudeCodeCommand: String {
        let path = toolPath
        let quoted = path.contains(" ") ? "'\(path.replacingOccurrences(of: "'", with: "'\\''"))'" : path
        return "claude mcp add fenestra -- \(quoted) mcp"
    }

    private static var mcpConfiguration: String {
        let config = ["mcpServers": ["fenestra": ["command": toolPath, "args": ["mcp"]]]]
        guard let data = try? JSONSerialization.data(
            withJSONObject: config, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]) else { return "" }
        return String(decoding: data, as: UTF8.self)
    }

    var body: some View {
        Form {
            Section {
                Toggle("Allow AI agents and scripts to arrange windows", isOn: $settings.externalControlEnabled)
                Text("AI agents such as Claude connect to Fenestra through the Model Context Protocol (MCP), with the fenestra tool bundled in the app. They can list your displays and windows and arrange them; nothing leaves your Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Group {
                Section {
                    CopyableSnippet(text: Self.claudeCodeCommand)
                } header: {
                    Text(verbatim: "Claude Code")
                } footer: {
                    Text("Run in a terminal.")
                }
                Section {
                    CopyableSnippet(text: Self.mcpConfiguration)
                } header: {
                    Text("Claude Desktop, Cursor and other MCP apps")
                } footer: {
                    Text("Add to the app's MCP configuration file. These settings point to this copy of Fenestra: copy them again if you move the app.")
                }
            }
            .disabled(!settings.externalControlEnabled)
        }
        .formStyle(.grouped)
    }
}

/// Monospaced text with a button that copies it to the clipboard.
private struct CopyableSnippet: View {
    let text: String
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: text)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
                copied = true
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    copied = false
                }
            } label: {
                Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
            }
        }
    }
}

private struct AboutTab: View {
    /// The documentation site has an English root and a French section.
    private static var documentationURL: URL {
        let french = Bundle.main.preferredLocalizations.first == "fr"
        return URL(string: french ? "https://famaridon.github.io/fenestra/fr/" : "https://famaridon.github.io/fenestra/")!
    }

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "Version \(short) (\(build))"
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "rectangle.split.2x1").font(.system(size: 48))
            Text("Fenestra").font(.title.bold())
            Text(version).foregroundStyle(.secondary)
            Text("Window snapping with the mouse or the keyboard, as on Windows.")
                .multilineTextAlignment(.center)
            Link("Documentation", destination: Self.documentationURL)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

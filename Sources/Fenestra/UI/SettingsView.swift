import SwiftUI

/// Settings window with one tab per topic.
struct SettingsView: View {
    @Environment(AppController.self) private var controller

    var body: some View {
        TabView {
            GeneralTab(settings: controller.settings)
                .tabItem { Label("General", systemImage: "gearshape") }
            ZonesTab(settings: controller.settings)
                .tabItem { Label("Zones", systemImage: "rectangle.split.2x2") }
            ShortcutsTab(settings: controller.settings)
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
            ExcludedAppsView()
                .tabItem { Label("Exclusions", systemImage: "nosign") }
            AboutTab()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 520, height: 460)
    }
}

private struct GeneralTab: View {
    @Bindable var settings: Settings
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var launchError: String?
    @State private var screenRecordingGranted = ScreenRecordingPermission.isGranted

    var body: some View {
        Form {
            Toggle("Launch at login", isOn: Binding(
                get: { launchAtLogin },
                set: { newValue in
                    do {
                        try LaunchAtLogin.set(newValue)
                        launchError = nil
                    } catch {
                        launchError = error.localizedDescription
                    }
                    launchAtLogin = LaunchAtLogin.isEnabled
                }
            ))
            if let launchError {
                Text(launchError).font(.caption).foregroundStyle(.red)
            }
            Toggle("Snap windows by dragging them to an edge", isOn: $settings.dragSnapEnabled)
            Toggle("Restore original size when unsnapping", isOn: $settings.restoreOnUnsnap)
            Toggle("Shared border between snapped windows", isOn: $settings.sharedBorderEnabled)
            Toggle("Snap Assist", isOn: $settings.snapAssistEnabled)
            Toggle("Window previews in Snap Assist", isOn: Binding(
                get: { settings.snapAssistPreviews },
                set: { newValue in
                    settings.snapAssistPreviews = newValue
                    if newValue && !screenRecordingGranted {
                        screenRecordingGranted = ScreenRecordingPermission.request()
                    }
                }
            ))
            .disabled(!settings.snapAssistEnabled)
            if settings.snapAssistPreviews && !screenRecordingGranted {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Previews need the Screen & System Audio Recording permission. Without it, Snap Assist shows the app icons. Once the permission is granted, relaunch Fenestra if macOS asks you to.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Open System Settings") { ScreenRecordingPermission.openSystemSettings() }
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
        .onAppear { screenRecordingGranted = ScreenRecordingPermission.isGranted }
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

private struct ShortcutsTab: View {
    @Bindable var settings: Settings

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
        }
        .formStyle(.grouped)
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

import SwiftUI

/// Settings window with one tab per topic.
struct SettingsView: View {
    @Environment(AppController.self) private var controller

    var body: some View {
        TabView {
            GeneralTab(settings: controller.settings)
                .tabItem { Label("Général", systemImage: "gearshape") }
            ZonesTab(settings: controller.settings)
                .tabItem { Label("Zones", systemImage: "rectangle.split.2x2") }
            ShortcutsTab(settings: controller.settings)
                .tabItem { Label("Raccourcis", systemImage: "keyboard") }
            ExcludedAppsView()
                .tabItem { Label("Exclusions", systemImage: "nosign") }
            AboutTab()
                .tabItem { Label("À propos", systemImage: "info.circle") }
        }
        .frame(width: 520, height: 460)
    }
}

private struct GeneralTab: View {
    @Bindable var settings: Settings
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var launchError: String?

    var body: some View {
        Form {
            Toggle("Lancer à l'ouverture de session", isOn: Binding(
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
            Toggle("Placer les fenêtres en les glissant vers un bord", isOn: $settings.dragSnapEnabled)
            Toggle("Restaurer la taille d'origine au décollage", isOn: $settings.restoreOnUnsnap)
            Toggle("Bordure partagée entre fenêtres collées", isOn: $settings.sharedBorderEnabled)
            Toggle("Snap Assist", isOn: $settings.snapAssistEnabled)
            LabeledContent("Marge entre fenêtres : \(Int(settings.gap)) pt") {
                Slider(value: $settings.gap, in: 0...32, step: 1)
            }
            Stepper("Taille des coins : \(Int(settings.cornerLength)) pt",
                    value: $settings.cornerLength, in: 40...300, step: 10)
        }
        .formStyle(.grouped)
    }
}

private struct ZonesTab: View {
    @Bindable var settings: Settings

    private let groups: [(String, [Zone])] = [
        ("Moitiés", [.leftHalf, .rightHalf, .topHalf, .bottomHalf]),
        ("Quarts", [.topLeft, .topRight, .bottomLeft, .bottomRight]),
        ("Plein écran", [.maximize]),
        ("Tiers", [.leftThird, .centerThird, .rightThird, .leftTwoThirds, .rightTwoThirds]),
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
            Section("Écran vertical") {
                Toggle("Le bord haut passe en plein écran", isOn: $settings.portraitTopEdgeMaximizes)
                Toggle("Bords gauche/droit actifs", isOn: $settings.portraitSideEdgesEnabled)
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
            Button("Rétablir les raccourcis par défaut") { settings.resetShortcuts() }
        }
        .formStyle(.grouped)
    }
}

private struct AboutTab: View {
    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "Version \(short) (\(build))"
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "rectangle.split.2x1").font(.system(size: 48))
            Text("Panes").font(.title.bold())
            Text(version).foregroundStyle(.secondary)
            Text("Placement de fenêtres par glisser ou au clavier, comme sous Windows.")
                .multilineTextAlignment(.center)
            Text("Documentation : `cd docs && pnpm dev` dans le dépôt du projet.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

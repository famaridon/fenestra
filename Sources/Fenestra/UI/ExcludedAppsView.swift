import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Editable list of applications Fenestra never snaps.
struct ExcludedAppsView: View {
    @Environment(AppController.self) private var controller
    @State private var selection: String?

    var body: some View {
        VStack(alignment: .leading) {
            Text("Fenestra never moves the windows of these apps.")
                .foregroundStyle(.secondary)
            List(controller.settings.excludedBundleIdentifiers, id: \.self, selection: $selection) { id in
                HStack {
                    if let icon = Self.icon(for: id) {
                        Image(nsImage: icon).resizable().frame(width: 20, height: 20)
                    }
                    Text(Self.name(for: id))
                    Spacer()
                    Text(id).font(.caption).foregroundStyle(.secondary)
                }
            }
            HStack {
                Button { addApp() } label: { Image(systemName: "plus") }
                Button { removeSelection() } label: { Image(systemName: "minus") }
                    .disabled(selection == nil)
            }
        }
        .padding()
    }

    private func addApp() {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(filePath: "/Applications")
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url,
              let id = Bundle(url: url)?.bundleIdentifier else { return }
        if !controller.settings.excludedBundleIdentifiers.contains(id) {
            controller.settings.excludedBundleIdentifiers.append(id)
        }
    }

    private func removeSelection() {
        guard let selection else { return }
        controller.settings.excludedBundleIdentifiers.removeAll { $0 == selection }
        self.selection = nil
    }

    private static func icon(for id: String) -> NSImage? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: id)
            .map { NSWorkspace.shared.icon(forFile: $0.path()) }
    }

    private static func name(for id: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id),
              let bundle = Bundle(url: url) else { return id }
        return bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? url.deletingPathExtension().lastPathComponent
    }
}

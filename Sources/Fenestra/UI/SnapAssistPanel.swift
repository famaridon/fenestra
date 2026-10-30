import AppKit
import SwiftUI

struct SnapAssistCandidate: Identifiable {
    let id: Int
    let title: String
    let appName: String
    let icon: NSImage?
}

/// What the panel shows; thumbnails arrive after the panel is on screen.
@MainActor
@Observable
final class SnapAssistModel {
    let candidates: [SnapAssistCandidate]
    let showsPreviews: Bool
    var thumbnails: [Int: NSImage] = [:]

    init(candidates: [SnapAssistCandidate], showsPreviews: Bool) {
        self.candidates = candidates
        self.showsPreviews = showsPreviews
    }
}

/// Panel listing the windows that can fill the space left by a snap (F8).
@MainActor
final class SnapAssistPanel {
    private let panel: NSPanel
    private var keyMonitor: Any?
    private var mouseMonitor: Any?
    private var onDismiss: (() -> Void)?

    init() {
        panel = NSPanel(contentRect: .zero,
                        styleMask: [.borderless, .nonactivatingPanel, .hudWindow],
                        backing: .buffered, defer: true)
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
    }

    /// `frame` is in Cocoa coordinates.
    func show(frame: CGRect, model: SnapAssistModel,
              onSelect: @escaping (Int) -> Void, onDismiss: @escaping () -> Void) {
        removeMonitors()
        self.onDismiss = onDismiss

        let effect = NSVisualEffectView()
        effect.material = .hudWindow
        effect.appearance = NSAppearance(named: .vibrantDark)
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.wantsLayer = true
        effect.layer?.cornerRadius = 12
        effect.layer?.masksToBounds = true

        let tiles = SnapAssistGrid(model: model) { [weak self] id in
            onSelect(id)
            self?.hide()
        }
        let hosting = NSHostingView(rootView: tiles)
        // The panel must keep the zone's frame: never let SwiftUI's intrinsic size drive the window.
        hosting.sizingOptions = []
        effect.frame = CGRect(origin: .zero, size: frame.size)
        hosting.frame = effect.bounds
        hosting.autoresizingMask = [.width, .height]
        effect.addSubview(hosting)
        panel.contentView = effect
        panel.setFrame(frame, display: true)
        panel.orderFrontRegardless()

        // The panel never becomes key (non-activating), so Escape has to be caught globally.
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return }
            Task { @MainActor in self?.dismiss() }
        }
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in self?.dismiss() }
        }
    }

    func hide() {
        removeMonitors()
        onDismiss = nil
        panel.orderOut(nil)
    }

    private func dismiss() {
        let callback = onDismiss
        hide()
        callback?()
    }

    private func removeMonitors() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        if let mouseMonitor { NSEvent.removeMonitor(mouseMonitor) }
        keyMonitor = nil
        mouseMonitor = nil
    }
}

private struct SnapAssistGrid: View {
    let model: SnapAssistModel
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: model.showsPreviews ? 200 : 120), spacing: 12)],
                      spacing: 12) {
                ForEach(model.candidates) { candidate in
                    Button { onSelect(candidate.id) } label: {
                        if model.showsPreviews {
                            PreviewTile(candidate: candidate, thumbnail: model.thumbnails[candidate.id])
                        } else {
                            IconTile(candidate: candidate)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .foregroundStyle(.white)
    }
}

/// App icon, app name and window title.
private struct IconTile: View {
    let candidate: SnapAssistCandidate

    var body: some View {
        VStack(spacing: 4) {
            if let icon = candidate.icon {
                Image(nsImage: icon).resizable().frame(width: 48, height: 48)
            }
            Text(candidate.appName).font(.headline).lineLimit(1)
            Text(candidate.title).font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .contentShape(Rectangle())
    }
}

/// Small app icon and title above a thumbnail of the window, as on Windows 11.
/// The app icon stands in for the thumbnail until it arrives, or if it cannot be captured.
private struct PreviewTile: View {
    let candidate: SnapAssistCandidate
    let thumbnail: NSImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let icon = candidate.icon {
                    Image(nsImage: icon).resizable().frame(width: 16, height: 16)
                }
                Text(candidate.title.isEmpty ? candidate.appName : candidate.title)
                    .font(.caption).lineLimit(1)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.08))
                if let thumbnail {
                    Image(nsImage: thumbnail).resizable().aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(4)
                } else if let icon = candidate.icon {
                    Image(nsImage: icon).resizable().frame(width: 48, height: 48)
                }
            }
            .frame(height: 120)
        }
        .padding(8)
        .contentShape(Rectangle())
    }
}

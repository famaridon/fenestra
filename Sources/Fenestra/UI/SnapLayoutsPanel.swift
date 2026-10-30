import AppKit
import SwiftUI

/// Palette of layouts shown under a window's zoom button, as on Windows 11.
@MainActor
final class SnapLayoutsPanel {
    private static let tileLength: CGFloat = 88
    private static let spacing: CGFloat = 10
    private static let padding: CGFloat = 12
    private static let maxColumns = 4

    private let panel: NSPanel
    private var keyMonitor: Any?
    private var mouseMonitor: Any?
    private var onDismiss: (() -> Void)?

    var isVisible: Bool { panel.isVisible }
    /// Cocoa coordinates.
    var frame: CGRect { panel.frame }

    init() {
        panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: true)
        // Above the menu macOS shows itself when the pointer rests on the zoom button.
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
    }

    /// `button` and `area` (the visible frame of the window's display) are in Cocoa coordinates;
    /// `screenSize` gives the aspect ratio of the miniature displays.
    func show(layouts: [SnapLayout], screenSize: CGSize, below button: CGRect, within area: CGRect,
              onSelect: @escaping (Zone) -> Void, onDismiss: @escaping () -> Void) {
        removeMonitors()
        self.onDismiss = onDismiss

        let aspect = screenSize.width > 0 ? screenSize.height / screenSize.width : 0.625
        let tile = aspect <= 1
            ? CGSize(width: Self.tileLength, height: (Self.tileLength * aspect).rounded())
            : CGSize(width: (Self.tileLength / aspect).rounded(), height: Self.tileLength)
        let columns = min(layouts.count, Self.maxColumns)
        let rows = (layouts.count + columns - 1) / columns
        let size = CGSize(
            width: CGFloat(columns) * tile.width + CGFloat(columns - 1) * Self.spacing + 2 * Self.padding,
            height: CGFloat(rows) * tile.height + CGFloat(rows - 1) * Self.spacing + 2 * Self.padding)
        // Under the button, left-aligned with it, kept inside the display.
        var origin = CGPoint(x: button.minX - Self.padding, y: button.minY - 6 - size.height)
        origin.x = min(max(origin.x, area.minX + 4), area.maxX - size.width - 4)
        origin.y = max(origin.y, area.minY + 4)

        let effect = NSVisualEffectView()
        effect.material = .popover
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.wantsLayer = true
        effect.layer?.cornerRadius = 12
        effect.layer?.masksToBounds = true

        let grid = SnapLayoutsGrid(layouts: layouts, tile: tile, columns: columns,
                                   spacing: Self.spacing, padding: Self.padding) { [weak self] zone in
            self?.hide()
            onSelect(zone)
        }
        let hosting = NSHostingView(rootView: grid)
        hosting.sizingOptions = []
        effect.frame = CGRect(origin: .zero, size: size)
        hosting.frame = effect.bounds
        hosting.autoresizingMask = [.width, .height]
        effect.addSubview(hosting)
        panel.contentView = effect
        panel.setFrame(CGRect(origin: origin, size: size), display: true)
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

private struct SnapLayoutsGrid: View {
    let layouts: [SnapLayout]
    let tile: CGSize
    let columns: Int
    let spacing: CGFloat
    let padding: CGFloat
    let onSelect: (Zone) -> Void

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(tile.width), spacing: spacing), count: columns),
                  alignment: .leading, spacing: spacing) {
            ForEach(layouts) { layout in
                LayoutTile(layout: layout, size: tile, onSelect: onSelect)
            }
        }
        .padding(padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// A miniature display split into the zones of one layout; each zone is clickable.
private struct LayoutTile: View {
    let layout: SnapLayout
    let size: CGSize
    let onSelect: (Zone) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6).fill(.primary.opacity(0.06))
            ForEach(layout.zones) { zone in
                let frame = zone.frame(in: CGRect(origin: .zero, size: size), gap: 6)
                ZoneCell(name: zone.localizedName) { onSelect(zone) }
                    .frame(width: frame.width, height: frame.height)
                    .offset(x: frame.minX, y: frame.minY)
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

private struct ZoneCell: View {
    let name: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovered ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary.opacity(0.18)))
                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(.primary.opacity(0.2)))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(name)
        .accessibilityLabel(name)
    }
}

import AppKit

/// Translucent, click-through panel showing where the dragged window will land.
@MainActor
final class SnapPreviewPanel {
    private let panel: NSPanel

    init() {
        panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: true)
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.hasShadow = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.isReleasedWhenClosed = false

        let view = NSView()
        view.wantsLayer = true
        view.layer?.cornerRadius = 10
        view.layer?.borderWidth = 2
        panel.contentView = view
        updateColors()
    }

    /// `frame` is in Cocoa coordinates.
    func show(frame: CGRect) {
        updateColors()
        if panel.isVisible {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.08
                panel.animator().setFrame(frame, display: true)
            }
        } else {
            panel.setFrame(frame, display: true)
        }
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func updateColors() {
        guard let layer = panel.contentView?.layer else { return }
        let accent = NSColor.controlAccentColor
        layer.backgroundColor = accent.withAlphaComponent(0.22).cgColor
        layer.borderColor = accent.withAlphaComponent(0.6).cgColor
    }
}

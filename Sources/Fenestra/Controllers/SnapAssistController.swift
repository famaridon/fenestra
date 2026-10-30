import AppKit

/// F8: after a snap (drag or keyboard), offers the other windows for the remaining space.
@MainActor
final class SnapAssistController {
    private let settings: Settings
    private unowned let snapController: SnapController
    private let panel = SnapAssistPanel()
    private var windows: [Int: AXWindow] = [:]

    init(settings: Settings, snapController: SnapController) {
        self.settings = settings
        self.snapController = snapController
    }

    func offer(after window: AXWindow, zone: Zone, screen: ScreenInfo) {
        guard let complement = zone.complement else { return }
        let neighbors = snapController.snappedWindows(on: screen.id, excluding: window)
        // As on Windows, nothing to offer when another snapped window already fills the space.
        guard !neighbors.contains(where: { $0.1.zone.overlaps(complement) }) else { return }
        let snapped = Set(neighbors.map(\.0))
        let others = AXWindowFinder.visibleStandardWindows().filter {
            $0 != window && !snapped.contains($0)
                && !settings.isExcluded(bundleIdentifier: $0.bundleIdentifier)
        }
        guard !others.isEmpty else { return }
        windows = Dictionary(uniqueKeysWithValues: others.enumerated().map { ($0.offset, $0.element) })
        let candidates = others.enumerated().map {
            SnapAssistCandidate(id: $0.offset, title: $0.element.title ?? "", appName: $0.element.appName ?? "",
                                icon: $0.element.appIcon)
        }
        panel.show(frame: snapController.cocoaFrame(of: complement, on: screen), candidates: candidates,
                   onSelect: { [weak self] id in
                       guard let self, let chosen = self.windows[id] else { return }
                       self.snapController.placeExternal(window: chosen, zone: complement, screen: screen)
                       chosen.raise()
                       self.dismiss()
                   },
                   onDismiss: {})
    }

    func dismiss() {
        panel.hide()
        windows = [:]
    }
}

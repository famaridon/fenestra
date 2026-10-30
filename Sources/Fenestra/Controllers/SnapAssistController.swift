import AppKit

/// F8: after a snap (drag or keyboard), offers the other windows for the remaining space.
@MainActor
final class SnapAssistController {
    private let settings: Settings
    private unowned let snapController: SnapController
    private let panel = SnapAssistPanel()
    private var windows: [Int: AXWindow] = [:]
    private var captureTask: Task<Void, Never>?
    /// Largest thumbnail, in points; tiles are smaller, this keeps them sharp.
    private static let thumbnailSize = CGSize(width: 480, height: 320)

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
        let model = SnapAssistModel(candidates: candidates,
                                    showsPreviews: settings.snapAssistPreviews && ScreenRecordingPermission.isGranted)
        panel.show(frame: snapController.cocoaFrame(of: complement, on: screen), model: model,
                   onSelect: { [weak self] id in
                       guard let self, let chosen = self.windows[id] else { return }
                       self.snapController.placeExternal(window: chosen, zone: complement, screen: screen)
                       chosen.raise()
                       self.dismiss()
                   },
                   onDismiss: { [weak self] in self?.stopCapture() })
        if model.showsPreviews { startCapture(of: others, into: model) }
    }

    func dismiss() {
        stopCapture()
        panel.hide()
        windows = [:]
    }

    /// The panel is already on screen: thumbnails fill in one by one.
    private func startCapture(of others: [AXWindow], into model: SnapAssistModel) {
        let targets = others.enumerated().compactMap { index, window -> (id: Int, window: WindowDescriptor)? in
            guard let frame = window.frame else { return nil }
            return (index, WindowDescriptor(pid: window.pid, frame: frame, title: window.title))
        }
        captureTask = Task { [weak model] in
            await WindowThumbnailer.capture(targets, maxSize: Self.thumbnailSize) { id, image in
                model?.thumbnails[id] = image
            }
        }
    }

    private func stopCapture() {
        captureTask?.cancel()
        captureTask = nil
    }
}

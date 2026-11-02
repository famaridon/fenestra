import CoreGraphics

/// Snap Assist: after a snap by the user, offers the other windows for the remaining space,
/// and places the chosen one there.
@MainActor
final class OfferSnapAssist: SnapFollowUp {
    /// Largest thumbnail, in points; tiles are smaller, this keeps them sharp.
    private static let thumbnailSize = CGSize(width: 480, height: 320)

    private let store: SnapStore
    private let manageable: ManageableWindows
    private let place: PlaceWindowInZone
    private let presenter: any SnapAssistPresenter
    private let thumbnails: any WindowThumbnails
    private let screenRecording: any ScreenRecordingAccess
    private let settings: any SnapSettingsProvider

    private var candidates: [Int: any WindowHandle] = [:]
    private var captureTask: Task<Void, Never>?

    init(store: SnapStore, manageable: ManageableWindows, place: PlaceWindowInZone,
         presenter: any SnapAssistPresenter, thumbnails: any WindowThumbnails,
         screenRecording: any ScreenRecordingAccess, settings: any SnapSettingsProvider) {
        self.store = store
        self.manageable = manageable
        self.place = place
        self.presenter = presenter
        self.thumbnails = thumbnails
        self.screenRecording = screenRecording
        self.settings = settings
    }

    func windowSnapped(_ window: any WindowHandle, zone: Zone, screen: ScreenInfo) {
        let settings = settings.snapSettings
        guard settings.snapAssistEnabled, let complement = zone.complement,
              settings.enabledZones.contains(complement) else { return }
        let neighbors = store.snappedWindows(on: screen.id, excluding: window)
        // As on Windows, nothing to offer when another snapped window already fills the space.
        guard !neighbors.contains(where: { $0.record.zone.overlaps(complement) }) else { return }
        let snapped = Set(neighbors.map { WindowRef($0.window) })
        let others = manageable.all().filter { !$0.isSame(as: window) && !snapped.contains(WindowRef($0)) }
        guard !others.isEmpty else { return }
        candidates = Dictionary(uniqueKeysWithValues: others.enumerated().map { ($0.offset, $0.element) })
        let tiles = others.enumerated().map {
            SnapAssistCandidate(id: $0.offset, title: $0.element.title ?? "", appName: $0.element.appName ?? "",
                                pid: $0.element.pid)
        }
        let showsPreviews = settings.snapAssistPreviews && screenRecording.isGranted
        presenter.show(frame: complement.frame(in: screen.visibleFrame, gap: settings.gap),
                       candidates: tiles, showsPreviews: showsPreviews,
                       onSelect: { [weak self] id in self?.choose(id, zone: complement, screen: screen) },
                       onDismiss: { [weak self] in self?.stopCapture() })
        if showsPreviews { startCapture(of: others) }
    }

    func cancel() {
        stopCapture()
        presenter.hide()
        candidates = [:]
    }

    private func choose(_ id: Int, zone: Zone, screen: ScreenInfo) {
        guard let chosen = candidates[id] else { return }
        place.execute(chosen, zone: zone, on: screen)
        chosen.raise()
        cancel()
    }

    /// The panel is already on screen: thumbnails fill in one by one.
    private func startCapture(of others: [any WindowHandle]) {
        let targets = others.enumerated().compactMap { index, window -> (id: Int, window: WindowDescriptor)? in
            guard let frame = window.frame else { return nil }
            return (index, WindowDescriptor(pid: window.pid, frame: frame, title: window.title))
        }
        captureTask = Task { [weak self, thumbnails, presenter] in
            await thumbnails.capture(targets, maxSize: Self.thumbnailSize) { id, image, size in
                guard self != nil else { return }
                presenter.showThumbnail(image, size: size, for: id)
            }
        }
    }

    private func stopCapture() {
        captureTask?.cancel()
        captureTask = nil
    }
}

/// Snap Layouts: when the pointer rests on a window's zoom (green) button, offers a palette of
/// layouts; a click on a zone snaps the window there.
@MainActor
final class ShowSnapLayouts {
    private let locator: any ZoomButtonLocator
    private let pointer: any PointerState
    private let displays: any DisplayProvider
    private let manageable: ManageableWindows
    private let presenter: any SnapLayoutsPresenter
    private let snap: SnapWindowToZone
    private let settings: any SnapSettingsProvider

    init(locator: any ZoomButtonLocator, pointer: any PointerState, displays: any DisplayProvider,
         manageable: ManageableWindows, presenter: any SnapLayoutsPresenter, snap: SnapWindowToZone,
         settings: any SnapSettingsProvider) {
        self.locator = locator
        self.pointer = pointer
        self.displays = displays
        self.manageable = manageable
        self.presenter = presenter
        self.snap = snap
        self.settings = settings
    }

    /// Called once the pointer has rested for a moment: one Accessibility lookup per pause.
    func execute() {
        guard !presenter.isVisible, !pointer.isLeftButtonPressed,
              let (window, button) = locator.zoomButton(at: pointer.location),
              manageable.isManageable(window), let frame = window.frame,
              let screen = displays.currentLayout().screen(for: frame) else { return }
        let layouts = SnapLayout.available(for: screen.orientation, enabledZones: settings.snapSettings.enabledZones)
        guard !layouts.isEmpty else { return }
        presenter.show(layouts: layouts, below: button, within: screen.visibleFrame,
                       onSelect: { [weak self] zone in
                           self?.presenter.hide()
                           self?.snap.execute(window, zone: zone, on: screen)
                       },
                       onDismiss: { [weak self] in self?.presenter.hide() })
    }

    func dismiss() {
        presenter.hide()
    }
}

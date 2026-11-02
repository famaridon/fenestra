/// Puts every snapped window back in its zone after the displays changed (resolution, Dock,
/// display unplugged: the windows of a vanished display go to the first one).
@MainActor
final class ReapplySnapsAfterDisplayChange {
    private let store: SnapStore
    private let displays: any DisplayProvider
    private let place: PlaceWindowInZone

    init(store: SnapStore, displays: any DisplayProvider, place: PlaceWindowInZone) {
        self.store = store
        self.displays = displays
        self.place = place
    }

    func execute() {
        let layout = displays.currentLayout()
        for (window, record) in store.all {
            guard let screen = layout.screen(id: record.screenID) ?? layout.screens.first else { continue }
            place.execute(window, zone: record.zone, on: screen)
        }
    }
}

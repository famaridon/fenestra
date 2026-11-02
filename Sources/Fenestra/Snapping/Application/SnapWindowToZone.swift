/// Snap chosen by the user (hotkey, Snap Layouts palette): places the window, raises it,
/// then offers the follow-up (Snap Assist) for the remaining space.
@MainActor
final class SnapWindowToZone {
    private let place: PlaceWindowInZone
    private let followUp: any SnapFollowUp

    init(place: PlaceWindowInZone, followUp: any SnapFollowUp) {
        self.place = place
        self.followUp = followUp
    }

    func execute(_ window: any WindowHandle, zone: Zone, on screen: ScreenInfo) {
        followUp.cancel()
        place.execute(window, zone: zone, on: screen)
        window.raise()
        followUp.windowSnapped(window, zone: zone, screen: screen)
    }
}

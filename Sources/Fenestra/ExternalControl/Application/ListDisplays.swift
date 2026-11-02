/// `list_displays`: the displays in reading order, with their index.
@MainActor
final class ListDisplays {
    private let displays: any DisplayProvider

    init(displays: any DisplayProvider) {
        self.displays = displays
    }

    func execute() -> [ControlResults.DisplayInfo] {
        let layout = displays.currentLayout()
        let primary = layout.screen(matching: "primary")
        return layout.readingOrder.enumerated().map { offset, screen in
            ControlResults.DisplayInfo(index: offset + 1, id: screen.id, isPrimary: screen.id == primary?.id,
                                       orientation: screen.orientation.rawValue,
                                       frame: .init(screen.frame), visibleFrame: .init(screen.visibleFrame))
        }
    }
}

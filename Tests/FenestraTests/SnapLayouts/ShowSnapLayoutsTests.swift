import CoreGraphics
import Testing
@testable import Fenestra

@MainActor
private final class FakeZoomButtonLocator: ZoomButtonLocator {
    var hit: (window: any WindowHandle, buttonFrame: CGRect)?
    func zoomButton(at point: CGPoint) -> (window: any WindowHandle, buttonFrame: CGRect)? { hit }
}

@MainActor
private final class FakeLayoutsPresenter: SnapLayoutsPresenter {
    private(set) var layouts: [SnapLayout]?
    private var onSelect: ((Zone) -> Void)?
    var isVisible: Bool { layouts != nil }

    func show(layouts: [SnapLayout], below button: CGRect, within area: CGRect,
              onSelect: @escaping (Zone) -> Void, onDismiss: @escaping () -> Void) {
        self.layouts = layouts
        self.onSelect = onSelect
    }

    func hide() { layouts = nil }

    func select(_ zone: Zone) { onSelect?(zone) }
}

@MainActor
struct ShowSnapLayoutsTests {
    let harness = SnappingHarness()
    private let locator = FakeZoomButtonLocator()
    private let presenter = FakeLayoutsPresenter()

    private func makeUseCase() -> ShowSnapLayouts {
        ShowSnapLayouts(locator: locator, pointer: harness.pointer, displays: harness.displays,
                        manageable: harness.manageable, presenter: presenter, snap: harness.snap,
                        settings: harness.settings)
    }

    @Test func showsTheLayoutsOfTheDisplayAndSnapsToTheChosenZone() {
        let window = harness.window()
        locator.hit = (window, CGRect(x: 350, y: 205, width: 14, height: 14))
        harness.pointer.isLeftButtonPressed = false
        let useCase = makeUseCase()
        useCase.execute()
        #expect(presenter.layouts == SnapLayout.available(for: .landscape, enabledZones: Zone.defaultEnabled))

        // The palette's callbacks hold the use case weakly; the app keeps it alive, so does the test.
        withExtendedLifetime(useCase) { presenter.select(.rightHalf) }
        #expect(!presenter.isVisible)
        #expect(window.frame == CGRect(x: 960, y: 25, width: 960, height: 1055))
        #expect(window.raiseCount == 1)
        #expect(harness.followUp.snapped.map(\.zone) == [.rightHalf])
    }

    @Test func nothingWhileTheButtonIsPressedOrAwayFromTheZoomButton() {
        let window = harness.window()
        let useCase = makeUseCase()
        locator.hit = (window, CGRect(x: 350, y: 205, width: 14, height: 14))
        harness.pointer.isLeftButtonPressed = true
        useCase.execute()
        #expect(!presenter.isVisible)

        harness.pointer.isLeftButtonPressed = false
        locator.hit = nil
        useCase.execute()
        #expect(!presenter.isVisible)
    }
}

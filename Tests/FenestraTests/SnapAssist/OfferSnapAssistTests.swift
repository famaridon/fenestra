import CoreGraphics
import Testing
@testable import Fenestra

@MainActor
struct OfferSnapAssistTests {
    let harness = SnappingHarness()
    let presenter = FakeAssistPresenter()
    let screenRecording = FakeScreenRecording()
    let thumbnails = FakeThumbnails()

    private func makeAssist() -> OfferSnapAssist {
        OfferSnapAssist(store: harness.store, manageable: harness.manageable, place: harness.place,
                        presenter: presenter, thumbnails: thumbnails, screenRecording: screenRecording,
                        settings: harness.settings)
    }

    @Test func offersTheOtherWindowsForTheRemainingSpaceAndPlacesTheChosenOne() {
        let snapped = harness.window(1, app: "Safari")
        let mail = harness.window(2, app: "Mail")
        _ = harness.window(3, app: "Notes")
        let assist = makeAssist()
        harness.place.execute(snapped, zone: .leftHalf, on: Fixtures.primary)
        assist.windowSnapped(snapped, zone: .leftHalf, screen: Fixtures.primary)

        let rightHalf = CGRect(x: 960, y: 25, width: 960, height: 1055)
        #expect(presenter.frame == rightHalf)
        #expect(presenter.candidates.map(\.appName) == ["Mail", "Notes"])

        // The panel's callbacks hold the use case weakly; the app keeps it alive, so does the test.
        withExtendedLifetime(assist) { presenter.select(0) }
        #expect(mail.frame == rightHalf)
        #expect(mail.raiseCount == 1)
        #expect(harness.store.record(for: mail)?.zone == .rightHalf)
        #expect(!presenter.isShown)
    }

    @Test func nothingToOfferWhenASnappedWindowAlreadyFillsTheSpace() {
        let left = harness.window(1)
        let right = harness.window(2)
        _ = harness.window(3)
        harness.place.execute(right, zone: .rightHalf, on: Fixtures.primary)
        harness.place.execute(left, zone: .leftHalf, on: Fixtures.primary)
        makeAssist().windowSnapped(left, zone: .leftHalf, screen: Fixtures.primary)
        #expect(!presenter.isShown)
    }

    @Test func nothingWhenOffOrForAZoneWithoutComplement() {
        let window = harness.window(1)
        _ = harness.window(2)
        let assist = makeAssist()
        assist.windowSnapped(window, zone: .maximize, screen: Fixtures.primary)
        #expect(!presenter.isShown)
        harness.settings.snapSettings.snapAssistEnabled = false
        assist.windowSnapped(window, zone: .leftHalf, screen: Fixtures.primary)
        #expect(!presenter.isShown)
    }

    @Test func previewsNeedTheScreenRecordingPermission() async {
        let window = harness.window(1)
        _ = harness.window(2)
        harness.settings.snapSettings.snapAssistPreviews = true
        let assist = makeAssist()
        assist.windowSnapped(window, zone: .leftHalf, screen: Fixtures.primary)
        #expect(presenter.showsPreviews == false)

        screenRecording.isGranted = true
        assist.windowSnapped(window, zone: .leftHalf, screen: Fixtures.primary)
        #expect(presenter.showsPreviews == true)
    }

    @Test func cancelHidesThePanel() {
        let window = harness.window(1)
        _ = harness.window(2)
        let assist = makeAssist()
        assist.windowSnapped(window, zone: .leftHalf, screen: Fixtures.primary)
        assist.cancel()
        #expect(!presenter.isShown)
    }
}

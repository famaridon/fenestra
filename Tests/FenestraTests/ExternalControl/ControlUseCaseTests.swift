import CoreGraphics
import Testing
@testable import Fenestra

@MainActor
struct ApplyLayoutTests {
    let harness = SnappingHarness()
    let launcher = FakeLauncher()

    private func makeUseCase() -> ApplyLayout {
        ApplyLayout(manageable: harness.manageable, displays: harness.displays, store: harness.store,
                    place: harness.place, launcher: launcher, settings: harness.settings,
                    launchTimeout: .seconds(1), pollInterval: .milliseconds(1))
    }

    @Test func placesZonesAndRectsAndReportsTheRest() async {
        let safari = harness.window(1, app: "Safari")
        let xcode = harness.window(2, app: "Xcode")
        let spec = LayoutSpec(placements: [
            LayoutPlacement(app: "Safari", zone: .leftHalf),
            LayoutPlacement(app: "xcode", rect: FractionRect(x: 0.5, y: 0, width: 0.5, height: 1)),
            LayoutPlacement(app: "Mail", zone: .rightHalf),
        ])
        let report = await makeUseCase().execute(spec)

        #expect(safari.frame == CGRect(x: 0, y: 25, width: 960, height: 1055))
        #expect(harness.store.record(for: safari)?.zone == .leftHalf)
        #expect(xcode.frame == CGRect(x: 960, y: 25, width: 960, height: 1055))
        #expect(harness.store.record(for: xcode) == nil)
        #expect(report.placed.map(\.placement) == [0, 1])
        #expect(report.placed.map(\.display) == [1, 1])
        #expect(report.failed == [ControlResults.FailedPlacement(placement: 2, app: "Mail",
                                                                  reason: PlacementIssue.noWindow.description)])
        #expect(launcher.launched.isEmpty)
    }

    @Test func launchesTheMissingAppsThenPlacesTheirWindows() async {
        let mail = FakeWindow(id: 9, frame: CGRect(x: 100, y: 100, width: 500, height: 400), appName: "Mail",
                              bundleIdentifier: "com.apple.mail")
        launcher.onLaunch = { [harness] in harness.windows.windows.append(mail) }
        let spec = LayoutSpec(placements: [LayoutPlacement(app: "Mail", zone: .rightHalf)], launchApps: true)
        let report = await makeUseCase().execute(spec)
        #expect(launcher.launched == ["Mail"])
        #expect(report.placed.count == 1)
        #expect(mail.frame == CGRect(x: 960, y: 25, width: 960, height: 1055))
    }
}

@MainActor
struct ListUseCaseTests {
    @Test func listsDisplaysInReadingOrder() {
        let harness = SnappingHarness()
        let displays = ListDisplays(displays: harness.displays).execute()
        #expect(displays.map(\.index) == [1, 2])
        #expect(displays.map(\.isPrimary) == [true, false])
        #expect(displays.map(\.orientation) == ["landscape", "portrait"])
    }

    @Test func listsWindowsWithTheirDisplayAndZone() {
        let harness = SnappingHarness()
        let snapped = harness.window(1, app: "Safari")
        _ = harness.window(2, app: "Notes")
        harness.place.execute(snapped, zone: .leftHalf, on: Fixtures.primary)
        let windows = ListWindows(displays: harness.displays, manageable: harness.manageable,
                                  store: harness.store).execute()
        #expect(windows.map(\.app) == ["Safari", "Notes"])
        #expect(windows.map(\.zone) == [.leftHalf, nil])
        #expect(windows.map(\.display) == [1, 1])
    }
}

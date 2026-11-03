import CoreGraphics
import Testing
@testable import Fenestra

struct WorkspaceCaptureTests {
    @Test func snappedWindowsKeepTheirZoneAndTheOthersTheirFrame() {
        let windows = [
            CapturedWindow(bundleIdentifier: "com.apple.dt.Xcode", appName: "Xcode", title: "Fenestra",
                           frame: CGRect(x: 0, y: 25, width: 960, height: 1055), zone: .leftHalf),
            CapturedWindow(bundleIdentifier: nil, appName: "Safari", title: "GitHub",
                           frame: CGRect(x: 960, y: 25, width: 480, height: 527.5), zone: nil),
        ]
        let spec = WorkspaceCapture.layout(of: windows, screens: Fixtures.twoScreens, gap: 0)

        #expect(spec.placements == [
            LayoutPlacement(app: "com.apple.dt.Xcode", display: "1", zone: .leftHalf),
            LayoutPlacement(app: "Safari", display: "1", rect: FractionRect(x: 0.5, y: 0, width: 0.25, height: 0.5)),
        ])
        #expect(spec.launchApps == nil)
    }

    @Test func fractionsUndoTheGapSoApplyingGivesTheSameFrameBack() {
        let area = Fixtures.primary.visibleFrame
        let original = FractionRect(x: 0.25, y: 0.1, width: 0.5, height: 0.6)
        let frame = original.frame(in: area, gap: 12)
        let captured = WorkspaceCapture.fraction(of: frame, in: area, gap: 12)

        #expect(abs(captured.x - original.x) < 0.001)
        #expect(abs(captured.width - original.width) < 0.001)
        // `FractionRect.frame` rounds to whole points (`integral`), so the round trip is exact to 2 points.
        let back = captured.frame(in: area, gap: 12)
        #expect(abs(back.minX - frame.minX) <= 2 && abs(back.minY - frame.minY) <= 2)
        #expect(abs(back.maxX - frame.maxX) <= 2 && abs(back.maxY - frame.maxY) <= 2)
        #expect(captured.isValid)
    }

    @Test func windowsOffScreenAreBroughtBackInsideAndStayValid() {
        let area = Fixtures.primary.visibleFrame
        let offScreen = CGRect(x: -200, y: 800, width: 3000, height: 900)
        let captured = WorkspaceCapture.fraction(of: offScreen, in: area, gap: 0)

        #expect(captured == FractionRect(x: 0, y: 0.1469, width: 1, height: 0.8531))
        #expect(captured.isValid)
    }

    @Test func secondDisplayAndDuplicateAppsGetTitles() {
        let windows = [
            CapturedWindow(bundleIdentifier: "com.apple.Safari", appName: "Safari", title: "Docs ",
                           frame: CGRect(x: 2000, y: 0, width: 500, height: 500), zone: nil),
            CapturedWindow(bundleIdentifier: "com.apple.Safari", appName: "Safari", title: nil,
                           frame: CGRect(x: 100, y: 100, width: 500, height: 500), zone: .topLeft),
            CapturedWindow(bundleIdentifier: nil, appName: nil, title: "ghost",
                           frame: CGRect(x: 100, y: 100, width: 500, height: 500), zone: nil),
        ]
        let spec = WorkspaceCapture.layout(of: windows, screens: Fixtures.twoScreens, gap: 0)

        #expect(spec.placements.count == 2)
        #expect(spec.placements[0].app == "com.apple.Safari")
        #expect(spec.placements[0].title == "Docs")
        #expect(spec.placements[0].display == "2")
        #expect(spec.placements[1].title == nil)
        #expect(spec.placements[1].zone == .topLeft)
    }

    @Test func layoutForTheCurrentDisplaysDropsVanishedOnes() {
        let workspace = Workspace(name: "Desk", layout: LayoutSpec(placements: [
            LayoutPlacement(app: "Slack", display: "2", zone: .maximize),
            LayoutPlacement(app: "Xcode", display: "left", zone: .leftHalf),
            LayoutPlacement(app: "Mail", zone: .rightHalf),
        ]))
        let laptop = ScreenLayout(screens: [Fixtures.primary])
        let spec = WorkspaceLibrary.layout(of: workspace, for: laptop, launchApps: false)

        #expect(spec.placements.map(\.display) == [nil, "left", nil])
        #expect(spec.launchApps == false)
        #expect(WorkspaceLibrary.layout(of: workspace, for: Fixtures.twoScreens, launchApps: true).placements[0].display == "2")
    }

    @Test func namesAreUniqueCaseInsensitively() {
        let existing = [Workspace(name: "Code", layout: LayoutSpec(placements: [])),
                        Workspace(name: "Code 2", layout: LayoutSpec(placements: []))]
        #expect(WorkspaceLibrary.uniqueName(" code ", among: existing) == "code 3")
        #expect(WorkspaceLibrary.uniqueName("", among: existing) == "Workspace")
        #expect(WorkspaceLibrary.uniqueName("Code", among: existing, excluding: existing[0].id) == "Code")
        #expect(WorkspaceLibrary.index(named: "CODE 2", in: existing) == 1)
    }

    @Test func stackingOrderComesFromTheWindowServer() {
        let a = CGRect(x: 0, y: 0, width: 500, height: 500), b = CGRect(x: 600, y: 0, width: 500, height: 500)
        let windows = [
            CapturedWindow(bundleIdentifier: "a", appName: nil, title: nil, frame: a, zone: nil, pid: 1),
            CapturedWindow(bundleIdentifier: "b", appName: nil, title: nil, frame: b, zone: nil, pid: 2),
            CapturedWindow(bundleIdentifier: "c", appName: nil, title: nil, frame: a, zone: nil, pid: 3),
        ]
        let stacking = [
            StackedWindow(pid: 2, frame: b.offsetBy(dx: 1, dy: 1)),   // within tolerance
            StackedWindow(pid: 9, frame: a),                          // some other app's window
            StackedWindow(pid: 1, frame: a),
        ]
        #expect(WorkspaceCapture.sorted(windows, frontToBack: stacking).map(\.bundleIdentifier) == ["b", "a", "c"])
        #expect(WorkspaceCapture.sorted(windows, frontToBack: []).map(\.bundleIdentifier) == ["a", "b", "c"])
    }

    @Test func displaySignatureIgnoresIdsAndOrder() {
        let swapped = ScreenLayout(screens: [
            ScreenInfo(id: 9, frame: Fixtures.portrait.frame, visibleFrame: Fixtures.portrait.visibleFrame),
            ScreenInfo(id: 8, frame: Fixtures.primary.frame, visibleFrame: Fixtures.primary.visibleFrame),
        ])
        #expect(DisplaySignature(Fixtures.twoScreens).matches(swapped))
        #expect(!DisplaySignature(Fixtures.twoScreens).matches(ScreenLayout(screens: [Fixtures.primary])))
    }
}

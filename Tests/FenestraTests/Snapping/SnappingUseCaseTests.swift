import CoreGraphics
import Testing
@testable import Fenestra

@MainActor
struct SnapWithKeyboardTests {
    let harness = SnappingHarness()
    let leftHalf = CGRect(x: 0, y: 25, width: 960, height: 1055)

    @Test func snapsTheFrontmostWindowAndOffersSnapAssist() {
        let window = harness.window()
        harness.keyboard().execute(.left)
        #expect(window.frame == leftHalf)
        #expect(window.raiseCount == 1)
        #expect(harness.store.record(for: window)?.zone == .leftHalf)
        #expect(harness.followUp.cancelCount >= 1)
        #expect(harness.followUp.snapped.map(\.zone) == [.leftHalf])
    }

    @Test func restoresThePreSnapFrameWhenThereIsNoNeighbourLeft() {
        let original = CGRect(x: 300, y: 200, width: 800, height: 600)
        let window = harness.window(frame: original)
        let keyboard = harness.keyboard()
        keyboard.execute(.left)
        keyboard.execute(.left)
        #expect(window.frame == original)
        #expect(harness.store.record(for: window) == nil)
    }

    @Test func aDisabledZoneIsNeverUsed() {
        let original = CGRect(x: 300, y: 200, width: 800, height: 600)
        let window = harness.window(frame: original)
        harness.settings.snapSettings.enabledZones.remove(.leftHalf)
        harness.keyboard().execute(.left)
        #expect(window.frame == original)
        #expect(harness.followUp.snapped.isEmpty)
    }

    @Test func leavesExcludedAppsAndFixedSizeWindowsAlone() {
        let original = CGRect(x: 300, y: 200, width: 800, height: 600)
        let window = harness.window(frame: original, app: "Finder")
        harness.settings.snapSettings.excludedBundleIdentifiers = ["com.example.Finder"]
        harness.keyboard().execute(.left)
        #expect(window.frame == original)

        harness.settings.snapSettings.excludedBundleIdentifiers = []
        window.isResizable = false
        harness.keyboard().execute(.left)
        #expect(window.frame == original)
    }

    @Test func movesAnUnsnappedWindowToTheNextDisplayKeepingItsSize() throws {
        let window = harness.window()
        harness.keyboard().execute(.nextDisplay)
        let frame = try #require(window.frame)
        #expect(frame.size == CGSize(width: 800, height: 600))
        #expect(Fixtures.twoScreens.screen(for: frame)?.id == Fixtures.portrait.id)
    }
}

@MainActor
struct DragSnapSessionTests {
    let harness = SnappingHarness()
    let leftHalf = CGRect(x: 0, y: 25, width: 960, height: 1055)

    @Test func previewsThenSnapsTheWindowDroppedOnAnEdge() {
        let window = harness.window()
        let session = harness.dragSession()
        session.mouseDown(at: CGPoint(x: 500, y: 210))
        window.frame = CGRect(x: 0, y: 300, width: 800, height: 600)
        session.mouseDragged(at: CGPoint(x: 1, y: 500))
        #expect(harness.preview.frame == leftHalf)

        session.mouseUp(at: CGPoint(x: 1, y: 500))
        #expect(harness.preview.frame == nil)
        #expect(window.frame == leftHalf)
        #expect(harness.followUp.snapped.map(\.zone) == [.leftHalf])
        #expect(!session.isDragging)
    }

    @Test func noPreviewWhenDragSnappingIsOff() {
        let window = harness.window()
        harness.settings.snapSettings.dragSnapEnabled = false
        let session = harness.dragSession()
        session.mouseDown(at: CGPoint(x: 500, y: 210))
        window.frame = CGRect(x: 0, y: 300, width: 800, height: 600)
        session.mouseDragged(at: CGPoint(x: 1, y: 500))
        session.mouseUp(at: CGPoint(x: 1, y: 500))
        #expect(window.frame == CGRect(x: 0, y: 300, width: 800, height: 600))
        #expect(harness.followUp.snapped.isEmpty)
    }

    @Test func draggingASnappedWindowAwayGivesItsSizeBack() throws {
        let window = harness.window()
        harness.place.execute(window, zone: .leftHalf, on: Fixtures.primary)
        let session = harness.dragSession()
        session.mouseDown(at: CGPoint(x: 480, y: 35))
        window.frame = CGRect(x: 50, y: 25, width: 960, height: 1055)
        session.mouseDragged(at: CGPoint(x: 530, y: 35))
        #expect(try #require(window.frame).size == CGSize(width: 800, height: 600))
        #expect(harness.store.record(for: window) == nil)
    }

    @Test func resizingASnappedWindowGoesToTheResizeHandler() {
        let window = harness.window()
        harness.place.execute(window, zone: .leftHalf, on: Fixtures.primary)
        let session = harness.dragSession()
        session.mouseDown(at: CGPoint(x: 959, y: 500))
        window.frame = CGRect(x: 0, y: 25, width: 1060, height: 1055)
        session.mouseDragged(at: CGPoint(x: 1059, y: 500))
        #expect(harness.resizeHandler.resized.map(\.to) == [CGRect(x: 0, y: 25, width: 1060, height: 1055)])
        #expect(harness.preview.frame == nil)

        session.mouseUp(at: CGPoint(x: 1059, y: 500))
        #expect(harness.resizeHandler.ended == 1)
        #expect(harness.followUp.snapped.isEmpty)
    }
}

@MainActor
struct ReapplySnapsTests {
    @Test func windowsOfAVanishedDisplayGoToTheFirstOne() {
        let harness = SnappingHarness()
        let window = harness.window()
        harness.place.execute(window, zone: .topHalf, on: Fixtures.portrait)
        harness.displays.layout = ScreenLayout(screens: [Fixtures.primary])
        ReapplySnapsAfterDisplayChange(store: harness.store, displays: harness.displays, place: harness.place).execute()
        #expect(window.frame == Zone.topHalf.frame(in: Fixtures.primary.visibleFrame, gap: 0))
        #expect(harness.store.record(for: window)?.screenID == Fixtures.primary.id)
    }
}

@MainActor
struct SnapStoreTests {
    @Test func aMovedWindowIsNoLongerSnapped() {
        let harness = SnappingHarness()
        let moved = harness.window(1)
        let kept = harness.window(2)
        harness.place.execute(moved, zone: .leftHalf, on: Fixtures.primary)
        harness.place.execute(kept, zone: .rightHalf, on: Fixtures.primary)
        moved.frame = CGRect(x: 100, y: 100, width: 500, height: 500)

        let snapped = harness.store.snappedWindows(on: Fixtures.primary.id)
        #expect(snapped.compactMap { ($0.window as? FakeWindow)?.id } == [2])
        #expect(harness.store.record(for: moved) == nil)
    }

    @Test func aResnappedWindowKeepsItsFirstRestoreFrame() {
        let harness = SnappingHarness()
        let original = CGRect(x: 300, y: 200, width: 800, height: 600)
        let window = harness.window(frame: original)
        harness.place.execute(window, zone: .leftHalf, on: Fixtures.primary)
        harness.place.execute(window, zone: .rightHalf, on: Fixtures.primary)
        #expect(harness.store.record(for: window)?.restoreFrame == original)
    }
}

struct SnapGeometryTests {
    @Test func unsnapKeepsThePointerAtTheSameRatioInTheTitleBar() {
        let frame = CGRect(x: 0, y: 25, width: 1000, height: 1000)
        let restored = SnapGeometry.unsnappedFrame(restoring: CGSize(width: 400, height: 300), from: frame,
                                                   pointer: CGPoint(x: 250, y: 35))
        #expect(restored == CGRect(x: 150, y: 25, width: 400, height: 300))
    }

    @Test func proportionalMoveShrinksAndStaysInside() {
        let source = CGRect(x: 0, y: 0, width: 2000, height: 1000)
        let target = CGRect(x: 2000, y: 0, width: 1000, height: 500)
        let moved = SnapGeometry.proportionalFrame(CGRect(x: 1500, y: 500, width: 1200, height: 400),
                                                   from: source, to: target)
        #expect(moved == CGRect(x: 2000, y: 100, width: 1000, height: 400))
    }
}

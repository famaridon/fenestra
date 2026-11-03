import CoreGraphics
import Testing
@testable import Fenestra

@MainActor
struct WorkspaceUseCaseTests {
    let harness = SnappingHarness()
    let store = FakeWorkspaceStore()
    let launcher = FakeLauncher()
    let stacking = FakeWindowStacking()
    let workspaces: WorkspaceCollection

    init() {
        workspaces = WorkspaceCollection(store: store)
    }

    private func save() -> SaveWorkspace {
        SaveWorkspace(workspaces: workspaces, manageable: harness.manageable, displays: harness.displays,
                      store: harness.store, stacking: stacking, settings: harness.settings)
    }

    private func apply() -> ApplyWorkspace {
        let applyLayout = ApplyLayout(manageable: harness.manageable, displays: harness.displays, store: harness.store,
                                      place: harness.place, launcher: launcher, settings: harness.settings,
                                      launchTimeout: .seconds(1), pollInterval: .milliseconds(1))
        return ApplyWorkspace(workspaces: workspaces, displays: harness.displays, applyLayout: applyLayout)
    }

    @Test func savingCapturesTheScreenAndPersists() {
        let xcode = harness.window(1, app: "Xcode")
        harness.place.execute(xcode, zone: .leftHalf, on: Fixtures.primary)
        let safari = harness.window(2, frame: CGRect(x: 2000, y: 0, width: 540, height: 950), app: "Safari")
        // Safari is in front of Xcode on screen, whatever the order the Accessibility API gives.
        stacking.windows = [StackedWindow(pid: safari.pid, frame: safari.frame!), StackedWindow(pid: xcode.pid, frame: xcode.frame!)]

        let saved = save().execute(name: " Code ")

        #expect(saved.name == "Code")
        #expect(saved.layout.placements == [
            LayoutPlacement(app: "com.example.Safari", display: "2",
                            rect: FractionRect(x: 0.0741, y: 0.2211, width: 0.5, height: 0.5)),
            LayoutPlacement(app: "com.example.Xcode", display: "1", zone: .leftHalf),
        ])
        #expect(store.saved == [saved])
        #expect(workspaces.all == [saved])
    }

    @Test func savingAgainUpdatesTheLayoutAndKeepsTheShortcut() {
        let shortcut = KeyboardShortcut(keyCode: 18, modifiers: KeyboardShortcut.controlFlag | KeyboardShortcut.optionFlag)
        var first = save().execute(name: "Code", layout: LayoutSpec(placements: [LayoutPlacement(app: "Xcode", zone: .maximize)]))
        first.shortcut = shortcut
        workspaces.upsert(first)

        let given = LayoutSpec(placements: [LayoutPlacement(app: "Safari", zone: .rightHalf)])
        let second = save().execute(name: "code", layout: given)

        #expect(second.id == first.id)
        #expect(second.name == "Code")
        #expect(second.layout == given)
        #expect(second.shortcut == shortcut)
        #expect(workspaces.all.count == 1)
        #expect(store.saveCount == 3)
    }

    @Test func applyingPlacesTheWindowsAndAdaptsToTheDisplays() async throws {
        let safari = harness.window(1, app: "Safari")
        save().execute(name: "Desk", layout: LayoutSpec(placements: [
            LayoutPlacement(app: "Safari", display: "3", zone: .rightHalf),
        ]))

        let report = try await apply().execute(named: "desk", launchApps: false)

        #expect(report.failed.isEmpty)
        #expect(report.placed.map(\.display) == [1])
        #expect(safari.frame == CGRect(x: 960, y: 25, width: 960, height: 1055))
        #expect(harness.store.record(for: safari)?.zone == .rightHalf)
        #expect(launcher.launched.isEmpty)
    }

    @Test func applyingLaunchesMissingAppsByDefault() async throws {
        save().execute(name: "Mail", layout: LayoutSpec(placements: [LayoutPlacement(app: "Mail", zone: .maximize)]))
        _ = try await apply().execute(named: "Mail")
        #expect(launcher.launched == ["Mail"])
    }

    @Test func unknownNamesThrowAndDeleteRemoves() async throws {
        save().execute(name: "Code", layout: LayoutSpec(placements: [LayoutPlacement(app: "Xcode", zone: .maximize)]))
        #expect(ListWorkspaces(workspaces: workspaces).execute() == [
            WorkspaceSummary(name: "Code", windows: 1, shortcut: nil, automatic: false),
        ])
        await #expect(throws: ApplyWorkspace.UnknownWorkspace.self) { try await apply().execute(named: "Nope") }
        #expect(throws: ApplyWorkspace.UnknownWorkspace.self) { try DeleteWorkspace(workspaces: workspaces).execute(named: "Nope") }
        try DeleteWorkspace(workspaces: workspaces).execute(named: "CODE")
        #expect(workspaces.all.isEmpty)
        #expect(store.saved.isEmpty)
    }
}

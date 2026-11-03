import CoreGraphics
import Testing
@testable import Fenestra

@MainActor
struct ApplyWorkspaceForDisplaysTests {
    let harness = SnappingHarness(layout: ScreenLayout(screens: [Fixtures.primary]))
    let launcher = FakeLauncher()
    let workspaces = WorkspaceCollection(store: FakeWorkspaceStore())

    private func makeUseCase() -> ApplyWorkspaceForDisplays {
        let applyLayout = ApplyLayout(manageable: harness.manageable, displays: harness.displays, store: harness.store,
                                      place: harness.place, launcher: launcher, settings: harness.settings,
                                      launchTimeout: .seconds(1), pollInterval: .milliseconds(1))
        let apply = ApplyWorkspace(workspaces: workspaces, displays: harness.displays, applyLayout: applyLayout)
        return ApplyWorkspaceForDisplays(workspaces: workspaces, displays: harness.displays, applyWorkspace: apply)
    }

    private func desk() -> Workspace {
        Workspace(name: "Desk", layout: LayoutSpec(placements: [
            LayoutPlacement(app: "Safari", display: "2", zone: .maximize),
            LayoutPlacement(app: "Mail", zone: .leftHalf),
        ]), displays: DisplaySignature(Fixtures.twoScreens))
    }

    @Test func appliesTheWorkspaceOfTheNewDisplaysWithoutLaunchingApps() async {
        let safari = harness.window(1, app: "Safari")
        workspaces.upsert(desk())
        let useCase = makeUseCase()

        harness.displays.layout = Fixtures.twoScreens
        let applied = await useCase.execute()

        #expect(applied?.name == "Desk")
        #expect(safari.frame == Fixtures.portrait.visibleFrame)
        #expect(launcher.launched.isEmpty)
    }

    @Test func doesNothingAtLaunchWhenTheDisplaysDidNotChangeOrWithoutMatch() async {
        harness.window(1, app: "Safari")
        workspaces.upsert(desk())
        let useCase = makeUseCase()

        #expect(await useCase.execute() == nil)                       // same displays as at init
        harness.displays.layout = Fixtures.twoScreens
        #expect(await useCase.execute()?.name == "Desk")
        #expect(await useCase.execute() == nil)                       // already applied for these displays
        harness.displays.layout = ScreenLayout(screens: [Fixtures.portrait])
        #expect(await useCase.execute() == nil)                       // no workspace for a lone portrait display
    }

    @Test func workspacesWithoutDisplaysAreNeverAutomatic() async {
        var manual = desk()
        manual.displays = nil
        workspaces.upsert(manual)
        let useCase = makeUseCase()
        harness.displays.layout = Fixtures.twoScreens
        #expect(await useCase.execute() == nil)
    }
}

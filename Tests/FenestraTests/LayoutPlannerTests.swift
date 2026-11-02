import CoreGraphics
import Foundation
import Testing
@testable import Fenestra

struct LayoutPlannerTests {
    let safari = LayoutWindow(bundleIdentifier: "com.apple.Safari", appName: "Safari", title: "Apple")
    let safariGitHub = LayoutWindow(bundleIdentifier: "com.apple.Safari", appName: "Safari", title: "GitHub - Fenestra")
    let xcode = LayoutWindow(bundleIdentifier: "com.apple.dt.Xcode", appName: "Xcode", title: "Fenestra")

    @Test func decodesTheJSONAnAgentSends() throws {
        let json = """
        {"placements":[
          {"app":"Xcode","zone":"leftTwoThirds"},
          {"app":"com.apple.Safari","title":"github","display":"2","rect":{"x":0,"y":0,"width":0.5,"height":1}}
        ],"launch_apps":true}
        """
        let spec = try JSONDecoder().decode(LayoutSpec.self, from: Data(json.utf8))
        #expect(spec.launchApps == true)
        #expect(spec.placements[0] == LayoutPlacement(app: "Xcode", zone: .leftTwoThirds))
        #expect(spec.placements[1].rect == FractionRect(x: 0, y: 0, width: 0.5, height: 1))
        #expect(spec.placements[1].display == "2")
    }

    @Test func matchesBundleIdentifierOrNameIgnoringCase() {
        #expect(LayoutPlanner.matches(LayoutPlacement(app: "safari"), safari))
        #expect(LayoutPlanner.matches(LayoutPlacement(app: "COM.APPLE.SAFARI"), safari))
        #expect(!LayoutPlanner.matches(LayoutPlacement(app: "Saf"), safari))
        #expect(LayoutPlanner.matches(LayoutPlacement(app: "Safari", title: "github"), safariGitHub))
        #expect(!LayoutPlanner.matches(LayoutPlacement(app: "Safari", title: "github"), safari))
    }

    @Test func eachWindowIsUsedOnceInFrontToBackOrder() {
        let placements = [LayoutPlacement(app: "Safari"), LayoutPlacement(app: "Safari"), LayoutPlacement(app: "Safari")]
        #expect(LayoutPlanner.assign(placements, to: [safari, xcode, safariGitHub]) == [0, 2, nil])
    }

    @Test func titledPlacementsPickBeforeGenericOnes() {
        let placements = [LayoutPlacement(app: "Safari"), LayoutPlacement(app: "Safari", title: "GitHub")]
        #expect(LayoutPlanner.assign(placements, to: [safariGitHub, safari]) == [1, 0])
    }

    @Test func plansZonesAndRectsOnTheRequestedDisplay() throws {
        let spec = LayoutSpec(placements: [
            LayoutPlacement(app: "Xcode", zone: .leftHalf),
            LayoutPlacement(app: "Safari", display: "right", rect: FractionRect(x: 0, y: 0.5, width: 1, height: 0.5)),
        ])
        let plan = LayoutPlanner.plan(spec, windows: [safari, xcode], layout: Fixtures.twoScreens, gap: 0)
        let first = try plan[0].get(), second = try plan[1].get()
        #expect(first.windowIndex == 1)
        #expect(first.screen == Fixtures.primary)
        #expect(first.zone == .leftHalf)
        #expect(first.frame == Zone.leftHalf.frame(in: Fixtures.primary.visibleFrame, gap: 0))
        #expect(second.windowIndex == 0)
        #expect(second.screen == Fixtures.portrait)
        #expect(second.zone == nil)
        #expect(second.frame == CGRect(x: 1920, y: 530, width: 1080, height: 950))
    }

    @Test func reportsEachProblemPerPlacement() {
        let spec = LayoutSpec(placements: [
            LayoutPlacement(app: "Xcode"),
            LayoutPlacement(app: "Xcode", zone: .maximize, rect: FractionRect(x: 0, y: 0, width: 1, height: 1)),
            LayoutPlacement(app: "Xcode", rect: FractionRect(x: 0.5, y: 0, width: 0.8, height: 1)),
            LayoutPlacement(app: "Xcode", display: "7", zone: .maximize),
            LayoutPlacement(app: "Mail", zone: .maximize),
        ])
        let issues = LayoutPlanner.plan(spec, windows: [xcode], layout: Fixtures.twoScreens, gap: 0).map { result -> PlacementIssue? in
            if case .failure(let issue) = result { issue } else { nil }
        }
        #expect(issues == [.noTarget, .ambiguousTarget, .invalidRect, .unknownDisplay("7"), .noWindow])
    }

    @Test func rectKeepsTheGapRuleOfZones() {
        let area = CGRect(x: 0, y: 0, width: 900, height: 600)
        let half = FractionRect(x: 0, y: 0, width: 0.5, height: 1)
        #expect(half.frame(in: area, gap: 10) == Zone.leftHalf.frame(in: area, gap: 10))
    }

    @Test func displaySelectors() {
        let layout = Fixtures.twoScreens
        #expect(layout.screen(matching: nil) == Fixtures.primary)
        #expect(layout.screen(matching: "Main") == Fixtures.primary)
        #expect(layout.screen(matching: "1") == Fixtures.primary)
        #expect(layout.screen(matching: "2") == Fixtures.portrait)
        #expect(layout.screen(matching: "right") == Fixtures.portrait)
        #expect(layout.screen(matching: "id:2") == Fixtures.portrait)
        #expect(layout.screen(matching: "3") == nil)
        #expect(layout.screen(matching: "middle") == nil)
    }
}

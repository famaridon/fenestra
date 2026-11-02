import CoreGraphics

/// `apply_layout`: places several windows at once (zones or fractions of a display), launching the
/// missing apps first when asked. The first placement ends up in front.
@MainActor
final class ApplyLayout {
    private let manageable: ManageableWindows
    private let displays: any DisplayProvider
    private let store: SnapStore
    private let place: PlaceWindowInZone
    private let launcher: any AppLauncher
    private let settings: any SnapSettingsProvider
    private let launchTimeout: Duration
    private let pollInterval: Duration

    init(manageable: ManageableWindows, displays: any DisplayProvider, store: SnapStore,
         place: PlaceWindowInZone, launcher: any AppLauncher, settings: any SnapSettingsProvider,
         launchTimeout: Duration = .seconds(10), pollInterval: Duration = .milliseconds(250)) {
        self.manageable = manageable
        self.displays = displays
        self.store = store
        self.place = place
        self.launcher = launcher
        self.settings = settings
        self.launchTimeout = launchTimeout
        self.pollInterval = pollInterval
    }

    func execute(_ spec: LayoutSpec) async -> ControlResults.LayoutReport {
        var windows = manageable.all()
        if spec.launchApps == true {
            let missing = missingApps(spec, windows: windows)
            if !missing.isEmpty {
                await launcher.launch(missing)
                windows = await waitForWindows(spec)
            }
        }
        let layout = displays.currentLayout()
        let plan = LayoutPlanner.plan(spec, windows: descriptors(windows), layout: layout,
                                      gap: settings.snapSettings.gap)
        var report = ControlResults.LayoutReport(placed: [], failed: [])
        var placedWindows: [any WindowHandle] = []
        for (index, result) in plan.enumerated() {
            let placement = spec.placements[index]
            switch result {
            case .failure(let issue):
                report.failed.append(.init(placement: index, app: placement.app, reason: issue.description))
            case .success(let planned):
                let window = windows[planned.windowIndex]
                let actual: CGRect?
                if let zone = planned.zone {
                    place.execute(window, zone: zone, on: planned.screen)
                    actual = window.frame
                } else {
                    // An arbitrary frame: the window is no longer in a zone.
                    store.remove(window)
                    actual = window.setFrame(planned.frame)
                }
                guard let actual else {
                    report.failed.append(.init(placement: index, app: placement.app,
                                               reason: "the window refused to move"))
                    continue
                }
                placedWindows.append(window)
                report.placed.append(.init(placement: index, app: window.appName, title: window.title,
                                           display: layout.displayIndex(of: planned.screen) ?? 0,
                                           zone: planned.zone, frame: .init(actual)))
            }
        }
        for window in placedWindows.reversed() { window.raise() }
        return report
    }

    private func descriptors(_ windows: [any WindowHandle]) -> [LayoutWindow] {
        windows.map { LayoutWindow(bundleIdentifier: $0.bundleIdentifier, appName: $0.appName, title: $0.title) }
    }

    /// Apps of the placements left without a window, without duplicates.
    private func missingApps(_ spec: LayoutSpec, windows: [any WindowHandle]) -> [String] {
        let assignment = LayoutPlanner.assign(spec.placements, to: descriptors(windows))
        var seen = Set<String>()
        return spec.placements.indices.compactMap { i in
            guard assignment[i] == nil else { return nil }
            let app = spec.placements[i].app
            return seen.insert(app.lowercased()).inserted ? app : nil
        }
    }

    /// Polls until every placement has a window, or the timeout expires.
    private func waitForWindows(_ spec: LayoutSpec) async -> [any WindowHandle] {
        let deadline = ContinuousClock.now + launchTimeout
        while true {
            let windows = manageable.all()
            let complete = !LayoutPlanner.assign(spec.placements, to: descriptors(windows)).contains(nil)
            if complete || ContinuousClock.now >= deadline { return windows }
            try? await Task.sleep(for: pollInterval)
        }
    }
}

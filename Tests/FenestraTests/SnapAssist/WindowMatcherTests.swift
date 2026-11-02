import CoreGraphics
import Testing
@testable import Fenestra

struct WindowMatcherTests {
    let frame = CGRect(x: 100, y: 50, width: 800, height: 600)

    func window(pid: pid_t = 42, frame: CGRect? = nil, title: String? = "Docs") -> WindowDescriptor {
        WindowDescriptor(pid: pid, frame: frame ?? self.frame, title: title)
    }

    @Test func matchesSameProcessAndFrame() {
        let candidates = [(id: 1, window: window(pid: 7)), (id: 2, window: window())]
        #expect(WindowMatcher.bestMatch(for: window(), among: candidates) == 2)
    }

    @Test func toleratesSmallFrameDifferences() {
        let candidates = [(id: 1, window: window(frame: frame.offsetBy(dx: 1, dy: -2)))]
        #expect(WindowMatcher.bestMatch(for: window(), among: candidates) == 1)
    }

    @Test func rejectsADifferentFrame() {
        let candidates = [(id: 1, window: window(frame: frame.offsetBy(dx: 10, dy: 0)))]
        #expect(WindowMatcher.bestMatch(for: window(), among: candidates) == nil)
    }

    @Test func titleBreaksTiesBetweenStackedWindows() {
        let candidates = [(id: 1, window: window(title: "Downloads")), (id: 2, window: window(title: "Docs"))]
        #expect(WindowMatcher.bestMatch(for: window(), among: candidates) == 2)
    }

    @Test func fallsBackToTheFirstWhenNoTitleMatches() {
        let candidates = [(id: 1, window: window(title: nil)), (id: 2, window: window(title: "Other"))]
        #expect(WindowMatcher.bestMatch(for: window(), among: candidates) == 1)
    }
}

import AppKit
import ApplicationServices
import os

private let log = Logger(subsystem: "com.florentamaridon.Panes", category: "accessibility")

/// Locates windows through the Accessibility API. Points are in AX coordinates.
@MainActor enum AXWindowFinder {
    /// Focused window of the frontmost application.
    static func frontmostWindow() -> AXWindow? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let pid = app.processIdentifier
        let appElement = applicationElement(pid: pid)
        guard let element = elementAttribute(appElement, kAXFocusedWindowAttribute) else { return nil }
        return AXWindow(element: element, pid: pid)
    }

    /// Window under `point`, or nil if there is none.
    static func window(at point: CGPoint) -> AXWindow? {
        let systemWide = AXUIElementCreateSystemWide()
        var hit: AXUIElement?
        let error = AXUIElementCopyElementAtPosition(systemWide, Float(point.x), Float(point.y), &hit)
        guard error == .success, let hit else {
            log.debug("element at position failed: \(error.rawValue)")
            return nil
        }
        AXUIElementSetMessagingTimeout(hit, 0.25)

        var pid: pid_t = 0
        guard AXUIElementGetPid(hit, &pid) == .success else { return nil }

        var role: CFTypeRef?
        AXUIElementCopyAttributeValue(hit, kAXRoleAttribute as CFString, &role)
        if (role as? String) == kAXWindowRole {
            return AXWindow(element: hit, pid: pid)
        }
        guard let element = elementAttribute(hit, kAXWindowAttribute) else { return nil }
        return AXWindow(element: element, pid: pid)
    }

    /// Non-minimized standard windows of every regular application except Panes.
    static func visibleStandardWindows() -> [AXWindow] {
        let ownBundleID = Bundle.main.bundleIdentifier
        var result: [AXWindow] = []
        for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular {
            if let ownBundleID, app.bundleIdentifier == ownBundleID { continue }
            let pid = app.processIdentifier
            let appElement = applicationElement(pid: pid)
            var value: CFTypeRef?
            let error = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value)
            guard error == .success, let elements = value as? [AXUIElement] else {
                log.debug("windows of pid \(pid) unavailable: \(error.rawValue)")
                continue
            }
            for element in elements {
                let window = AXWindow(element: element, pid: pid)
                if window.isStandardWindow && !window.isMinimized { result.append(window) }
            }
        }
        return result
    }

    // MARK: Helpers

    private static func applicationElement(pid: pid_t) -> AXUIElement {
        let element = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(element, 0.25)
        return element
    }

    /// Reads an attribute that holds another `AXUIElement`.
    private static func elementAttribute(_ element: AXUIElement, _ name: String) -> AXUIElement? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, name as CFString, &value)
        guard error == .success, let value, CFGetTypeID(value) == AXUIElementGetTypeID() else {
            log.debug("read \(name) failed: \(error.rawValue)")
            return nil
        }
        return unsafeDowncast(value as AnyObject, to: AXUIElement.self)
    }
}

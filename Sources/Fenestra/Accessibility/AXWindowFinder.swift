import AppKit
import ApplicationServices
import os

private let log = Logger(subsystem: "com.florentamaridon.Fenestra", category: "accessibility")

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

    /// The green button reports itself as a full screen button on recent macOS versions.
    private static let greenButtonSubroles: Set<String> = [kAXZoomButtonSubrole, kAXFullScreenButtonSubrole]

    /// Window whose zoom (green) button is under `point`, with the button's frame.
    static func zoomButton(at point: CGPoint) -> (window: AXWindow, buttonFrame: CGRect)? {
        let systemWide = AXUIElementCreateSystemWide()
        var hit: AXUIElement?
        guard AXUIElementCopyElementAtPosition(systemWide, Float(point.x), Float(point.y), &hit) == .success,
              let hit else { return nil }
        AXUIElementSetMessagingTimeout(hit, 0.25)
        var subrole: CFTypeRef?
        AXUIElementCopyAttributeValue(hit, kAXSubroleAttribute as CFString, &subrole)
        guard let subrole = subrole as? String, greenButtonSubroles.contains(subrole) else {
            log.debug("no green button under the pointer: \(subrole as? String ?? "-")")
            return nil
        }
        var pid: pid_t = 0
        guard AXUIElementGetPid(hit, &pid) == .success,
              let element = elementAttribute(hit, kAXWindowAttribute),
              let origin: CGPoint = value(hit, kAXPositionAttribute, type: .cgPoint),
              let size: CGSize = value(hit, kAXSizeAttribute, type: .cgSize) else { return nil }
        return (AXWindow(element: element, pid: pid), CGRect(origin: origin, size: size))
    }

    /// Non-minimized standard windows of every regular application except Fenestra.
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

    /// Reads an `AXValue`-boxed attribute (CGPoint, CGSize…).
    private static func value<T>(_ element: AXUIElement, _ name: String, type: AXValueType) -> T? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        let box = unsafeDowncast(value as AnyObject, to: AXValue.self)
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer { pointer.deallocate() }
        guard AXValueGetValue(box, type, pointer) else { return nil }
        return pointer.move()
    }
}

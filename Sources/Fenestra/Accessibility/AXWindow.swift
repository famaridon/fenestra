import AppKit
import ApplicationServices
import os

private let log = Logger(subsystem: "com.florentamaridon.Fenestra", category: "accessibility")

/// Wraps a window `AXUIElement`. Coordinates are in the AX space
/// (origin top-left of the primary screen, y pointing down).
/// Equality and hashing rely on `CFEqual` / `CFHash` of the element.
@MainActor final class AXWindow: Hashable {
    nonisolated(unsafe) let element: AXUIElement
    nonisolated let pid: pid_t

    init(element: AXUIElement, pid: pid_t) {
        self.element = element
        self.pid = pid
        // NF3: an unresponsive app must never block us for long.
        AXUIElementSetMessagingTimeout(element, 0.25)
    }

    // MARK: Geometry

    /// Current frame in AX coordinates, or nil if it cannot be read.
    var frame: CGRect? {
        guard let origin: CGPoint = axValue(kAXPositionAttribute, type: .cgPoint),
              let size: CGSize = axValue(kAXSizeAttribute, type: .cgSize) else { return nil }
        return CGRect(origin: origin, size: size)
    }

    /// Applies size, then position, then size again (some apps adjust the size
    /// after a move), and returns the frame actually obtained, or nil on error.
    @discardableResult
    func setFrame(_ frame: CGRect) -> CGRect? {
        let okSize1 = setAXValue(kAXSizeAttribute, frame.size, type: .cgSize)
        let okPos = setAXValue(kAXPositionAttribute, frame.origin, type: .cgPoint)
        let okSize2 = setAXValue(kAXSizeAttribute, frame.size, type: .cgSize)
        guard okSize1 || okPos || okSize2 else { return nil }
        return self.frame
    }

    // MARK: Attributes

    var title: String? { attribute(kAXTitleAttribute) }

    var isMinimized: Bool { (attribute(kAXMinimizedAttribute) as Bool?) ?? false }

    var isFullScreen: Bool { (attribute("AXFullScreen") as Bool?) ?? false }

    var isStandardWindow: Bool {
        let role: String? = attribute(kAXRoleAttribute)
        let subrole: String? = attribute(kAXSubroleAttribute)
        return role == kAXWindowRole && subrole == kAXStandardWindowSubrole
    }

    var isResizable: Bool {
        var settable: DarwinBoolean = false
        let error = AXUIElementIsAttributeSettable(element, kAXSizeAttribute as CFString, &settable)
        return error == .success && settable.boolValue
    }

    // MARK: Owning application

    private var application: NSRunningApplication? { NSRunningApplication(processIdentifier: pid) }

    var bundleIdentifier: String? { application?.bundleIdentifier }
    var appName: String? { application?.localizedName }
    var appIcon: NSImage? { application?.icon }

    /// Raises the window and activates its application.
    func raise() {
        let error = AXUIElementPerformAction(element, kAXRaiseAction as CFString)
        if error != .success { log.debug("raise failed: \(error.rawValue)") }
        application?.activate()
    }

    // MARK: Hashable

    nonisolated static func == (lhs: AXWindow, rhs: AXWindow) -> Bool {
        CFEqual(lhs.element, rhs.element)
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(CFHash(element))
    }

    // MARK: Helpers

    /// Reads an attribute whose value bridges directly to `T` (String, Bool…).
    private func attribute<T>(_ name: String) -> T? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, name as CFString, &value)
        guard error == .success else {
            log.debug("read \(name) failed: \(error.rawValue)")
            return nil
        }
        return value as? T
    }

    /// Reads an `AXValue`-boxed attribute (CGPoint, CGSize…).
    private func axValue<T>(_ name: String, type: AXValueType) -> T? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, name as CFString, &value)
        guard error == .success, let value, CFGetTypeID(value) == AXValueGetTypeID() else {
            log.debug("read \(name) failed: \(error.rawValue)")
            return nil
        }
        let box = unsafeDowncast(value as AnyObject, to: AXValue.self)
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer { pointer.deallocate() }
        guard AXValueGetValue(box, type, pointer) else { return nil }
        return pointer.move()
    }

    private func setAXValue<T>(_ name: String, _ newValue: T, type: AXValueType) -> Bool {
        var copy = newValue
        guard let box = withUnsafePointer(to: &copy, { AXValueCreate(type, $0) }) else { return false }
        let error = AXUIElementSetAttributeValue(element, name as CFString, box)
        if error != .success { log.debug("write \(name) failed: \(error.rawValue)") }
        return error == .success
    }
}

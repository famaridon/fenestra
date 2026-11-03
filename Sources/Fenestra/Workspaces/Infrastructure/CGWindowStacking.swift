import CoreGraphics
import Foundation

/// `WindowStacking` from the window server: `CGWindowListCopyWindowInfo` lists the on-screen windows front
/// to back, with their process and bounds (top-left origin, the AX space). No permission is needed for
/// that; window names would need Screen Recording and are not read.
@MainActor
final class CGWindowStacking: WindowStacking {
    func frontToBack() -> [StackedWindow] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return [] }
        return list.compactMap { info in
            // Layer 0 holds the ordinary windows; menus, the Dock and panels sit on other layers.
            guard (info[kCGWindowLayer as String] as? Int) == 0,
                  let pid = info[kCGWindowOwnerPID as String] as? pid_t,
                  let bounds = info[kCGWindowBounds as String] as? NSDictionary,
                  let frame = CGRect(dictionaryRepresentation: bounds) else { return nil }
            return StackedWindow(pid: pid, frame: frame)
        }
    }
}

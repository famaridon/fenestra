import AppKit
import os
import ScreenCaptureKit

private let log = Logger(subsystem: "com.florentamaridon.Fenestra", category: "capture")

/// Captures window thumbnails with ScreenCaptureKit (needs the Screen Recording permission).
@MainActor
enum WindowThumbnailer {
    /// Captures each target that ScreenCaptureKit can see, fitting it in `maxSize` points, and hands
    /// every image to `deliver` as soon as it is ready. Windows that cannot be matched are skipped.
    static func capture(_ targets: [(id: Int, window: WindowDescriptor)], maxSize: CGSize,
                        deliver: @escaping @MainActor (Int, NSImage) -> Void) async {
        let content: SCShareableContent
        do {
            content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
        } catch {
            log.error("shareable content unavailable: \(error.localizedDescription)")
            return
        }
        let scWindows = content.windows
        let candidates = scWindows.enumerated().compactMap { index, window -> (id: Int, window: WindowDescriptor)? in
            guard let app = window.owningApplication else { return nil }
            return (index, WindowDescriptor(pid: app.processID, frame: window.frame, title: window.title))
        }
        let scale = NSScreen.main?.backingScaleFactor ?? 2

        for target in targets {
            guard !Task.isCancelled else { return }
            guard let index = WindowMatcher.bestMatch(for: target.window, among: candidates) else {
                log.debug("no capturable window matches window \(target.id) of pid \(target.window.pid)")
                continue
            }
            let frame = scWindows[index].frame
            guard frame.width > 0, frame.height > 0 else { continue }
            let fit = min(maxSize.width / frame.width, maxSize.height / frame.height, 1)

            let filter = SCContentFilter(desktopIndependentWindow: scWindows[index])
            let configuration = SCStreamConfiguration()
            configuration.width = max(1, Int(frame.width * fit * scale))
            configuration.height = max(1, Int(frame.height * fit * scale))
            configuration.showsCursor = false
            configuration.ignoreShadowsSingleWindow = true
            do {
                let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
                guard !Task.isCancelled else { return }
                deliver(target.id, NSImage(cgImage: image, size: CGSize(width: frame.width * fit, height: frame.height * fit)))
            } catch {
                log.debug("capture failed for window \(target.id): \(error.localizedDescription)")
            }
        }
    }
}

import AppKit
import BlinkCore

@MainActor
enum FullscreenMonitor {
    static var isActive: Bool {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier,
              let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
                as? [[String: Any]]
        else { return false }

        let displays = NSScreen.screens.map(quartzDisplay)
        return windows.contains { window in
            guard (window[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value == pid,
                  window[kCGWindowLayer as String] as? Int == 0,
                  let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
                  let x = bounds["X"], let y = bounds["Y"],
                  let width = bounds["Width"], let height = bounds["Height"]
            else { return false }
            let frame = CGRect(x: x, y: y, width: width, height: height)
            return displays.contains { FullscreenGeometry.covers(display: $0.rect, menuBar: $0.menuBar, window: frame) }
        }
    }

    /// `NSScreen` measures from the bottom of the primary display upward; `CGWindowList` measures
    /// from its top downward.
    private static func quartzDisplay(_ screen: NSScreen) -> (rect: CGRect, menuBar: CGFloat) {
        let primaryMaxY = NSScreen.screens.first?.frame.maxY ?? 0
        let rect = CGRect(
            x: screen.frame.minX,
            y: primaryMaxY - screen.frame.maxY,
            width: screen.frame.width,
            height: screen.frame.height
        )
        return (rect, screen.frame.maxY - screen.visibleFrame.maxY)
    }
}

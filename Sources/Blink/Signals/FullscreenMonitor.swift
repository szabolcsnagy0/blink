import AppKit

/// A window of the frontmost app that exactly matches a display's size is a fullscreen window.
enum FullscreenMonitor {
    static var isActive: Bool {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier,
              let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
                as? [[String: Any]]
        else { return false }

        let displays = NSScreen.screens.map(\.frame.size)
        return windows.contains { window in
            guard window[kCGWindowOwnerPID as String] as? pid_t == pid,
                  window[kCGWindowLayer as String] as? Int == 0,
                  let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
                  let width = bounds["Width"], let height = bounds["Height"]
            else { return false }
            return displays.contains(CGSize(width: width, height: height))
        }
    }
}

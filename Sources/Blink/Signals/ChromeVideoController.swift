import AppKit
import ApplicationServices

/// Chrome does not expose web content to accessibility, so the page's own pause button is
/// unreachable and the media key stands in for it.
@MainActor
final class ChromeVideoController {
    /// Native browser chrome, the part of the tree Chrome does expose. Both exist only while a
    /// tab is audible, and posting the key with nothing playing would launch Music.
    private static let audibleButtons: Set<String> = ["Mute tab", "Control your music, videos, and more"]

    private var pausedByBlink = false

    func pauseIfPlaying(isFullscreen: Bool) {
        guard !pausedByBlink, isFullscreen, chromeIsAudible() else { return }
        MediaKey.sendPlayPause()
        pausedByBlink = true
    }

    func resumeIfNeeded() {
        guard pausedByBlink else { return }
        pausedByBlink = false
        MediaKey.sendPlayPause()
    }

    private func chromeIsAudible() -> Bool {
        guard Accessibility.isTrusted,
              let chrome = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == "com.google.Chrome" })
        else { return false }
        return hasAudibleButton(in: AXUIElementCreateApplication(chrome.processIdentifier))
    }

    private func hasAudibleButton(in root: AXUIElement) -> Bool {
        var pending = [root]
        var index = 0
        while index < pending.count, index < 2_000 {
            let element = pending[index]
            index += 1
            if value(of: element, attribute: kAXRoleAttribute as String) == kAXButtonRole as String,
               [kAXTitleAttribute, kAXDescriptionAttribute]
                   .contains(where: { Self.audibleButtons.contains(value(of: element, attribute: $0 as String) ?? "") }) {
                return true
            }
            pending.append(contentsOf: children(of: element))
        }
        return false
    }

    private func children(of element: AXUIElement) -> [AXUIElement] {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &value) == .success,
              let children = value as? [AXUIElement]
        else { return [] }
        return children
    }

    private func value(of element: AXUIElement, attribute: String) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value as? String
    }
}

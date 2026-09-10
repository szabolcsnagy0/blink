import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private var window: NSWindow?

    func show(store: SettingsStore) {
        if window == nil {
            let content = NSHostingView(rootView: SettingsView(store: store))
            content.frame.size = content.fittingSize
            let window = NSWindow(
                contentRect: content.frame,
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Blink Settings"
            window.contentView = content
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }
}

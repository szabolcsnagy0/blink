import AppKit
import SwiftUI

@MainActor
final class OverlayWindowController {
    var onSkip: () -> Void = {}

    private let state = BreakState()
    private var panels: [NSPanel] = []
    private var previousApp: NSRunningApplication?

    init() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, !self.panels.isEmpty else { return }
                self.tearDown()
                self.build()
            }
        }
    }

    func show(remaining: Int, total: Int) {
        state.remaining = remaining
        state.total = total
        guard panels.isEmpty else { return }
        previousApp = NSWorkspace.shared.frontmostApplication
        NSApp.activate()
        build()
    }

    func hide() {
        guard !panels.isEmpty else { return }
        tearDown()
        previousApp?.activate()
        previousApp = nil
    }

    private func build() {
        panels = NSScreen.screens.map { screen in
            let panel = OverlayPanel(
                contentRect: screen.frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.onCancel = { [weak self] in self?.onSkip() }
            panel.level = .screenSaver
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            panel.sharingType = .none
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.contentView = NSHostingView(
                rootView: OverlayView(state: state, onSkip: { [weak self] in self?.onSkip() })
            )
            panel.alphaValue = 0
            panel.orderFrontRegardless()
            panel.animator().alphaValue = 1
            return panel
        }
        (panels.first { $0.screen == NSScreen.main } ?? panels.first)?.makeKey()
    }

    private func tearDown() {
        panels.forEach { $0.orderOut(nil) }
        panels.removeAll()
    }
}

private final class OverlayPanel: NSPanel {
    var onCancel: () -> Void = {}

    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onCancel() } else { super.keyDown(with: event) }
    }
}

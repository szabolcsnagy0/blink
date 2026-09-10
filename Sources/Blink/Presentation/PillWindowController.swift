import AppKit
import SwiftUI

@MainActor
final class PillWindowController {
    var onSkip: () -> Void = {}

    private let state = BreakState()
    private var panel: NSPanel?

    func show(remaining: Int, total: Int) {
        state.remaining = remaining
        state.total = total
        guard panel == nil else { return }

        let content = NSHostingView(rootView: PillView(state: state, onSkip: { [weak self] in self?.onSkip() }))
        content.frame.size = content.fittingSize

        let panel = NSPanel(
            contentRect: content.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = content
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.sharingType = .none
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.setFrameOrigin(topRightOrigin(for: content.frame.size))
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        panel.animator().alphaValue = 1
        self.panel = panel
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
    }

    private func topRightOrigin(for size: CGSize) -> CGPoint {
        guard let frame = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame else { return .zero }
        return CGPoint(x: frame.maxX - size.width, y: frame.maxY - size.height)
    }
}

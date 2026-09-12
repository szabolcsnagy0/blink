import AppKit

/// The hardware play/pause key. The system routes it to the now-playing app, not the frontmost
/// one, so it still lands once a break window has taken focus. Posting requires Accessibility.
enum MediaKey {
    private static let playPause = 16
    private static let down = 0x0A
    private static let up = 0x0B

    static func sendPlayPause() {
        post(state: down)
        post(state: up)
    }

    /// `rcd` acts on the key up and ignores an unpaired down, so both are sent.
    private static func post(state: Int) {
        guard let event = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: UInt(state) << 8),
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: (playPause << 16) | (state << 8),
            data2: -1
        ) else { return }
        event.cgEvent?.post(tap: .cghidEventTap)
    }
}

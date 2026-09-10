import CoreGraphics

enum IdleMonitor {
    private static let anyEvent = CGEventType(rawValue: ~0)!

    static var seconds: Int {
        Int(CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyEvent))
    }
}

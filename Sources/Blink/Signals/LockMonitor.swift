import AppKit

@MainActor
final class LockMonitor {
    private var screenIsLocked = LockMonitor.currentSessionIsLocked()
    private var displaysAreAsleep = false

    var isLocked: Bool { screenIsLocked || displaysAreAsleep }

    init() {
        let distributed = DistributedNotificationCenter.default()
        let workspace = NSWorkspace.shared.notificationCenter
        observe(distributed, "com.apple.screenIsLocked") { $0.screenIsLocked = true }
        observe(distributed, "com.apple.screenIsUnlocked") { $0.screenIsLocked = false }
        observe(workspace, NSWorkspace.screensDidSleepNotification.rawValue) { $0.displaysAreAsleep = true }
        observe(workspace, NSWorkspace.screensDidWakeNotification.rawValue) { $0.displaysAreAsleep = false }
    }

    private static func currentSessionIsLocked() -> Bool {
        let session = CGSessionCopyCurrentDictionary() as? [String: Any]
        return session?["CGSSessionScreenIsLocked"] as? Bool ?? false
    }

    private func observe(
        _ center: NotificationCenter,
        _ name: String,
        _ update: @escaping @MainActor (LockMonitor) -> Void
    ) {
        center.addObserver(forName: .init(name), object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { if let self { update(self) } }
        }
    }
}

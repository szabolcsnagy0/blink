import AppKit
import BlinkCore

@MainActor
final class AppController: NSObject, NSApplicationDelegate {
    private let store = SettingsStore()
    private var scheduler: Scheduler
    private let statusItem = StatusItemController()
    private let overlay = OverlayWindowController()
    private let pill = PillWindowController()
    private let settingsWindow = SettingsWindowController()
    private let lockMonitor = LockMonitor()
    private let chromeVideo = ChromeVideoController()
    private var timer: Timer?
    private var isFullscreen = false

    override init() {
        scheduler = Scheduler(settings: store.settings)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        store.onChange = { [weak self] settings in
            self?.scheduler.handle(.settings(settings))
            self?.render()
        }
        statusItem.onCommand = { [weak self] command in self?.perform(command) }
        overlay.onSkip = { [weak self] in self?.perform(.skip) }
        pill.onSkip = { [weak self] in self?.perform(.skip) }

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        render()
    }

    private func tick() {
        isFullscreen = needsFullscreen && FullscreenMonitor.isActive
        scheduler.handle(.suppression(signals()))
        scheduler.handle(.tick(now: .now))
        render()
    }

    /// Disabled rules are skipped here to keep the tick cheap; the scheduler ignores them too.
    private func signals() -> Set<Suppression> {
        let settings = scheduler.settings
        var signals: Set<Suppression> = []
        if lockMonitor.isLocked { signals.insert(.locked) }
        if settings.response(for: .inCall) != .noChange, CallMonitor.isActive { signals.insert(.inCall) }
        if settings.response(for: .fullscreen) != .noChange, isFullscreen { signals.insert(.fullscreen) }
        return signals
    }

    private var needsFullscreen: Bool {
        let settings = scheduler.settings
        return settings.response(for: .fullscreen) != .noChange || settings.pauseChromeVideoDuringOverlay
    }

    private func perform(_ command: StatusItemController.Command) {
        switch command {
        case .takeBreak: scheduler.handle(.takeBreakNow)
        case .skip: scheduler.handle(.skip)
        case let .pause(duration): scheduler.handle(.pause(until: duration.deadline))
        case .resume: scheduler.handle(.resume)
        case .settings: settingsWindow.show(store: store)
        case .quit: NSApp.terminate(nil)
        }
        render()
    }

    private func render() {
        switch scheduler.presentation {
        case .none:
            overlay.hide()
            pill.hide()
            chromeVideo.resumeIfNeeded()
        case let .overlay(remaining):
            pill.hide()
            if scheduler.settings.pauseChromeVideoDuringOverlay { chromeVideo.pauseIfPlaying(isFullscreen: isFullscreen) }
            overlay.show(remaining: remaining, total: scheduler.settings.breakSeconds)
        case let .pill(remaining):
            overlay.hide()
            chromeVideo.resumeIfNeeded()
            pill.show(remaining: remaining, total: scheduler.settings.breakSeconds)
        }
        statusItem.update(indicator: scheduler.indicator, countdown: countdown, summary: summary)
    }

    private var countdown: String? {
        guard scheduler.settings.showCountdown, case .running = scheduler.state else { return nil }
        return scheduler.remaining.clock
    }

    private var summary: String {
        switch scheduler.state {
        case .running: "Next break in \(scheduler.remaining.clock)"
        case .onBreak: "On a break"
        case let .paused(_, until): "Paused until \(until.formatted(date: .omitted, time: .shortened))"
        case .suspended: "Paused by an active event"
        }
    }
}

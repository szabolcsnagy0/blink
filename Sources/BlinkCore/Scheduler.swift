import Foundation

/// The whole timing policy as a value type: no clocks, no timers, no system calls.
/// The app layer feeds it events once a second and renders whatever it reports.
public struct Scheduler: Sendable, Equatable {
    public enum State: Sendable, Equatable {
        case running(remaining: Int)
        case onBreak(remaining: Int)
        case paused(remaining: Int, until: Date)
        case suspended(remaining: Int)
    }

    public enum Event: Sendable {
        case tick(now: Date, idleSeconds: Int)
        case suppression(Set<Suppression>)
        case takeBreakNow
        case skip
        case pause(until: Date)
        case resume
        case settings(Settings)
    }

    public private(set) var state: State
    public private(set) var settings: Settings
    private var signals: Set<Suppression> = []

    public init(settings: Settings = Settings()) {
        self.settings = settings
        self.state = .running(remaining: settings.intervalSeconds)
    }

    private var active: Set<Suppression> { signals.filter(settings.honours) }

    public mutating func handle(_ event: Event) {
        switch event {
        case let .tick(now, idleSeconds):
            tick(now: now, idleSeconds: idleSeconds)
        case let .suppression(signals):
            self.signals = signals
            reconcileLock()
        case .takeBreakNow:
            state = .onBreak(remaining: settings.breakSeconds)
        case .skip:
            state = .running(remaining: settings.intervalSeconds)
        case let .pause(until):
            state = .paused(remaining: remaining, until: until)
        case .resume:
            if case let .paused(remaining, _) = state { state = .running(remaining: remaining) }
        case let .settings(settings):
            self.settings = settings
            clampToSettings()
            reconcileLock()
        }
    }

    private mutating func tick(now: Date, idleSeconds: Int) {
        switch state {
        case let .running(remaining):
            if settings.idleCountsAsBreak, idleSeconds >= settings.breakSeconds {
                state = .running(remaining: settings.intervalSeconds)
            } else if remaining <= 1 {
                state = .onBreak(remaining: settings.breakSeconds)
            } else {
                state = .running(remaining: remaining - 1)
            }
        case let .onBreak(remaining):
            state = remaining <= 1 ? .running(remaining: settings.intervalSeconds) : .onBreak(remaining: remaining - 1)
        case let .paused(remaining, until):
            if now >= until { state = .running(remaining: remaining) }
        case .suspended:
            break
        }
    }

    /// A lock arriving mid-break counts as the break taken.
    private mutating func reconcileLock() {
        switch (active.contains(.locked), state) {
        case let (true, .running(remaining)): state = .suspended(remaining: remaining)
        case (true, .onBreak): state = .suspended(remaining: settings.intervalSeconds)
        case let (false, .suspended(remaining)): state = .running(remaining: remaining)
        default: break
        }
    }

    private mutating func clampToSettings() {
        switch state {
        case let .running(remaining):
            state = .running(remaining: min(remaining, settings.intervalSeconds))
        case let .onBreak(remaining):
            state = .onBreak(remaining: min(remaining, settings.breakSeconds))
        case let .paused(remaining, until):
            state = .paused(remaining: min(remaining, settings.intervalSeconds), until: until)
        case let .suspended(remaining):
            state = .suspended(remaining: min(remaining, settings.intervalSeconds))
        }
    }

    /// Seconds left in the current state: until the next break, or until the break ends.
    public var remaining: Int {
        switch state {
        case let .running(remaining), let .onBreak(remaining),
             let .paused(remaining, _), let .suspended(remaining): remaining
        }
    }

    public var presentation: Presentation {
        guard case let .onBreak(remaining) = state else { return .none }
        return quiet || settings.style == .pill ? .pill(remaining: remaining) : .overlay(remaining: remaining)
    }

    public var indicator: Indicator {
        switch state {
        case .onBreak: .onBreak
        case .paused, .suspended: .paused
        case .running: quiet ? .quiet : .running
        }
    }

    private var quiet: Bool { !active.isDisjoint(with: [.inCall, .fullscreen]) }
}

import Foundation

/// The whole timing policy as a value type: no clocks, no timers, no system calls.
/// The app layer feeds it events once a second and renders whatever it reports.
public struct Scheduler: Sendable, Equatable {
    public enum State: Sendable, Equatable {
        case running(remaining: Int)
        case onBreak(remaining: Int)
        case paused(remaining: Int, until: Date)
        case suspended(phase: Phase, remaining: Int)
    }

    public enum Phase: Sendable, Equatable {
        case running, onBreak
    }

    public enum Event: Sendable {
        case tick(now: Date)
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

    private var responses: Set<EventResponse> { Set(signals.map(settings.response)) }

    public mutating func handle(_ event: Event) {
        switch event {
        case let .tick(now):
            tick(now: now)
        case let .suppression(signals):
            self.signals = signals
            reconcileSuppression()
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
            reconcileSuppression()
        }
    }

    private mutating func tick(now: Date) {
        switch state {
        case let .running(remaining):
            if remaining <= 1 {
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

    private mutating func reconcileSuppression() {
        switch (responses.contains(.pause), state) {
        case let (true, .running(remaining)): state = .suspended(phase: .running, remaining: remaining)
        case let (true, .onBreak(remaining)): state = .suspended(phase: .onBreak, remaining: remaining)
        case let (false, .suspended(phase, remaining)):
            state = phase == .running ? .running(remaining: remaining) : .onBreak(remaining: remaining)
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
        case let .suspended(phase, remaining):
            state = .suspended(phase: phase, remaining: min(remaining, settings.intervalSeconds))
        }
    }

    /// Seconds left in the current state: until the next break, or until the break ends.
    public var remaining: Int {
        switch state {
        case let .running(remaining), let .onBreak(remaining),
             let .paused(remaining, _), let .suspended(_, remaining): remaining
        }
    }

    /// When events disagree the least disruptive presentation wins, so a pill beats an overlay.
    public var presentation: Presentation {
        guard case let .onBreak(remaining) = state else { return .none }
        if responses.contains(.pill) { return .pill(remaining: remaining) }
        if responses.contains(.overlay) { return .overlay(remaining: remaining) }
        return settings.style == .pill ? .pill(remaining: remaining) : .overlay(remaining: remaining)
    }

    public var indicator: Indicator {
        switch state {
        case .onBreak: .onBreak
        case .paused, .suspended: .paused
        case .running: responses.isEmpty || responses == [.noChange] ? .running : .quiet
        }
    }
}

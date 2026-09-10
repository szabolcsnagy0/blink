public enum Suppression: Sendable, Hashable, CaseIterable {
    /// Screen locked or display asleep. Pauses the timer.
    case locked
    /// Camera or microphone in use by any app. Downgrades the break to a pill.
    case inCall
    /// Frontmost app is fullscreen. Downgrades the break to a pill.
    case fullscreen
}

public enum Presentation: Sendable, Equatable {
    case none
    case overlay(remaining: Int)
    case pill(remaining: Int)
}

public enum Indicator: Sendable, Equatable {
    case running
    case onBreak
    case paused
    case quiet
}

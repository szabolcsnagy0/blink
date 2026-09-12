public enum Suppression: Sendable, Hashable, CaseIterable {
    /// Screen locked or display asleep.
    case locked
    /// Camera or microphone in use by any app.
    case inCall
    /// Frontmost app is fullscreen.
    case fullscreen

    public var label: String {
        switch self {
        case .locked: "Screen is locked"
        case .inCall: "Camera or microphone is in use"
        case .fullscreen: "Frontmost app is fullscreen"
        }
    }
}

public enum EventResponse: String, Sendable, CaseIterable {
    case noChange, pause, pill, overlay

    public var label: String {
        switch self {
        case .noChange: "No change"
        case .pause: "Pause timer"
        case .pill: "Show pill"
        case .overlay: "Show overlay"
        }
    }
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

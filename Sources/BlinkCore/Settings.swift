import Foundation

public enum BreakStyle: String, Sendable, CaseIterable {
    case overlay, pill
}

public struct Settings: Sendable, Equatable {
    public var intervalMinutes: Int
    public var breakSeconds: Int
    public var style: BreakStyle
    public var showCountdown: Bool
    public var lockedResponse: EventResponse
    public var inCallResponse: EventResponse
    public var fullscreenResponse: EventResponse
    public var pauseChromeVideoDuringOverlay: Bool

    public init(
        intervalMinutes: Int = 20,
        breakSeconds: Int = 20,
        style: BreakStyle = .overlay,
        showCountdown: Bool = false,
        lockedResponse: EventResponse = .pause,
        inCallResponse: EventResponse = .pill,
        fullscreenResponse: EventResponse = .pill,
        pauseChromeVideoDuringOverlay: Bool = false
    ) {
        self.intervalMinutes = intervalMinutes
        self.breakSeconds = breakSeconds
        self.style = style
        self.showCountdown = showCountdown
        self.lockedResponse = lockedResponse
        self.inCallResponse = inCallResponse
        self.fullscreenResponse = fullscreenResponse
        self.pauseChromeVideoDuringOverlay = pauseChromeVideoDuringOverlay
    }

    public var intervalSeconds: Int { intervalMinutes * 60 }

    public func response(for suppression: Suppression) -> EventResponse {
        switch suppression {
        case .locked: lockedResponse
        case .inCall: inCallResponse
        case .fullscreen: fullscreenResponse
        }
    }
}

extension Settings {
    enum Key {
        static let intervalMinutes = "intervalMinutes"
        static let breakSeconds = "breakSeconds"
        static let style = "style"
        static let showCountdown = "showCountdown"
        static let lockedResponse = "lockedResponse"
        static let inCallResponse = "inCallResponse"
        static let fullscreenResponse = "fullscreenResponse"
        static let pauseChromeVideoDuringOverlay = "pauseChromeVideoDuringOverlay"
    }

    public static func load(from defaults: UserDefaults) -> Settings {
        var settings = Settings()
        if let minutes = defaults.object(forKey: Key.intervalMinutes) as? Int { settings.intervalMinutes = minutes }
        if let seconds = defaults.object(forKey: Key.breakSeconds) as? Int { settings.breakSeconds = seconds }
        if let raw = defaults.string(forKey: Key.style), let style = BreakStyle(rawValue: raw) { settings.style = style }
        if let value = defaults.object(forKey: Key.showCountdown) as? Bool { settings.showCountdown = value }
        if let raw = defaults.string(forKey: Key.lockedResponse), let response = EventResponse(rawValue: raw) {
            settings.lockedResponse = response
        } else if let value = defaults.object(forKey: "pauseWhenLocked") as? Bool {
            settings.lockedResponse = value ? .pause : .noChange
        }
        if let raw = defaults.string(forKey: Key.inCallResponse), let response = EventResponse(rawValue: raw) {
            settings.inCallResponse = response
        } else if let value = defaults.object(forKey: "pillDuringCalls") as? Bool {
            settings.inCallResponse = value ? .pill : .noChange
        }
        if let raw = defaults.string(forKey: Key.fullscreenResponse), let response = EventResponse(rawValue: raw) {
            settings.fullscreenResponse = response
        } else if let value = defaults.object(forKey: "pillDuringFullscreen") as? Bool {
            settings.fullscreenResponse = value ? .pill : .noChange
        }
        if let value = defaults.object(forKey: Key.pauseChromeVideoDuringOverlay) as? Bool {
            settings.pauseChromeVideoDuringOverlay = value
        }
        return settings
    }

    public func save(to defaults: UserDefaults) {
        defaults.set(intervalMinutes, forKey: Key.intervalMinutes)
        defaults.set(breakSeconds, forKey: Key.breakSeconds)
        defaults.set(style.rawValue, forKey: Key.style)
        defaults.set(showCountdown, forKey: Key.showCountdown)
        defaults.set(lockedResponse.rawValue, forKey: Key.lockedResponse)
        defaults.set(inCallResponse.rawValue, forKey: Key.inCallResponse)
        defaults.set(fullscreenResponse.rawValue, forKey: Key.fullscreenResponse)
        defaults.set(pauseChromeVideoDuringOverlay, forKey: Key.pauseChromeVideoDuringOverlay)
    }
}

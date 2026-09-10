import Foundation

public enum BreakStyle: String, Sendable, CaseIterable {
    case overlay, pill
}

public struct Settings: Sendable, Equatable {
    public var intervalMinutes: Int
    public var breakSeconds: Int
    public var style: BreakStyle
    public var showCountdown: Bool
    public var pauseWhenLocked: Bool
    public var idleCountsAsBreak: Bool
    public var pillDuringCalls: Bool
    public var pillDuringFullscreen: Bool

    public init(
        intervalMinutes: Int = 20,
        breakSeconds: Int = 20,
        style: BreakStyle = .overlay,
        showCountdown: Bool = false,
        pauseWhenLocked: Bool = true,
        idleCountsAsBreak: Bool = true,
        pillDuringCalls: Bool = true,
        pillDuringFullscreen: Bool = true
    ) {
        self.intervalMinutes = intervalMinutes
        self.breakSeconds = breakSeconds
        self.style = style
        self.showCountdown = showCountdown
        self.pauseWhenLocked = pauseWhenLocked
        self.idleCountsAsBreak = idleCountsAsBreak
        self.pillDuringCalls = pillDuringCalls
        self.pillDuringFullscreen = pillDuringFullscreen
    }

    public var intervalSeconds: Int { intervalMinutes * 60 }

    public func honours(_ suppression: Suppression) -> Bool {
        switch suppression {
        case .locked: pauseWhenLocked
        case .inCall: pillDuringCalls
        case .fullscreen: pillDuringFullscreen
        }
    }
}

extension Settings {
    enum Key {
        static let intervalMinutes = "intervalMinutes"
        static let breakSeconds = "breakSeconds"
        static let style = "style"
        static let showCountdown = "showCountdown"
        static let pauseWhenLocked = "pauseWhenLocked"
        static let idleCountsAsBreak = "idleCountsAsBreak"
        static let pillDuringCalls = "pillDuringCalls"
        static let pillDuringFullscreen = "pillDuringFullscreen"
    }

    public static func load(from defaults: UserDefaults) -> Settings {
        var settings = Settings()
        if let minutes = defaults.object(forKey: Key.intervalMinutes) as? Int { settings.intervalMinutes = minutes }
        if let seconds = defaults.object(forKey: Key.breakSeconds) as? Int { settings.breakSeconds = seconds }
        if let raw = defaults.string(forKey: Key.style), let style = BreakStyle(rawValue: raw) { settings.style = style }
        if let value = defaults.object(forKey: Key.showCountdown) as? Bool { settings.showCountdown = value }
        if let value = defaults.object(forKey: Key.pauseWhenLocked) as? Bool { settings.pauseWhenLocked = value }
        if let value = defaults.object(forKey: Key.idleCountsAsBreak) as? Bool { settings.idleCountsAsBreak = value }
        if let value = defaults.object(forKey: Key.pillDuringCalls) as? Bool { settings.pillDuringCalls = value }
        if let value = defaults.object(forKey: Key.pillDuringFullscreen) as? Bool { settings.pillDuringFullscreen = value }
        return settings
    }

    public func save(to defaults: UserDefaults) {
        defaults.set(intervalMinutes, forKey: Key.intervalMinutes)
        defaults.set(breakSeconds, forKey: Key.breakSeconds)
        defaults.set(style.rawValue, forKey: Key.style)
        defaults.set(showCountdown, forKey: Key.showCountdown)
        defaults.set(pauseWhenLocked, forKey: Key.pauseWhenLocked)
        defaults.set(idleCountsAsBreak, forKey: Key.idleCountsAsBreak)
        defaults.set(pillDuringCalls, forKey: Key.pillDuringCalls)
        defaults.set(pillDuringFullscreen, forKey: Key.pillDuringFullscreen)
    }
}

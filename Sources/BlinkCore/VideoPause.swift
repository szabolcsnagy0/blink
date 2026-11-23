/// When to tell Chrome to pause or resume video around an overlay. The page script pauses only
/// video that is playing fullscreen and resumes only what it paused itself, so repeating either
/// is harmless; this only has to send each once, on the overlay's edges.
public struct VideoPause: Sendable, Equatable {
    public enum Command: Sendable, Equatable { case pause, resume }

    private var paused = false

    public init() {}

    public mutating func render(overlay: Bool, enabled: Bool) -> Command? {
        if overlay, enabled, !paused {
            paused = true
            return .pause
        }
        if !overlay, paused {
            paused = false
            return .resume
        }
        return nil
    }
}

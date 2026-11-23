import Testing
@testable import BlinkCore

/// The command each render issued, given whether the overlay was up and the option enabled.
private func commands(_ renders: [(overlay: Bool, enabled: Bool)]) -> [VideoPause.Command?] {
    var pause = VideoPause()
    return renders.map { pause.render(overlay: $0.overlay, enabled: $0.enabled) }
}

@Test func anOverlayPausesOnceAndResumesOnce() {
    #expect(commands([
        (false, true), (true, true), (true, true), (true, true), (false, true), (false, true),
    ]) == [nil, .pause, nil, nil, .resume, nil])
}

@Test func aQuicklyRetriggeredOverlayPausesAgain() {
    #expect(commands([
        (true, true), (false, true), (true, true), (false, true),
    ]) == [.pause, .resume, .pause, .resume])
}

@Test func nothingIsSentWhileDisabled() {
    #expect(commands([(true, false), (true, false), (false, false)]) == [nil, nil, nil])
}

@Test func disablingDuringAnOverlayStillResumes() {
    #expect(commands([(true, true), (true, false), (false, false)]) == [.pause, nil, .resume])
}

@Test func enablingDuringAnOverlayPausesThen() {
    #expect(commands([(true, false), (true, true), (false, true)]) == [nil, .pause, .resume])
}

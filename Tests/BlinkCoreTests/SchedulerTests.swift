import Foundation
import Testing
@testable import BlinkCore

private let epoch = Date(timeIntervalSince1970: 0)

private extension Scheduler {
    mutating func advance(_ seconds: Int) {
        for second in 0..<seconds {
            handle(.tick(now: epoch.addingTimeInterval(Double(second))))
        }
    }
}

private let settings = Settings(intervalMinutes: 1, breakSeconds: 10)

@Test func intervalElapsesIntoBreak() {
    var scheduler = Scheduler(settings: settings)
    scheduler.advance(59)
    #expect(scheduler.state == .running(remaining: 1))
    scheduler.advance(1)
    #expect(scheduler.state == .onBreak(remaining: 10))
    #expect(scheduler.presentation == .overlay(remaining: 10))
}

@Test func breakEndsIntoNewInterval() {
    var scheduler = Scheduler(settings: settings)
    scheduler.handle(.takeBreakNow)
    scheduler.advance(10)
    #expect(scheduler.state == .running(remaining: 60))
    #expect(scheduler.presentation == .none)
}

@Test func lockSuspendsAndUnlockResumesWhereItLeftOff() {
    var scheduler = Scheduler(settings: settings)
    scheduler.advance(20)
    scheduler.handle(.suppression([.locked]))
    #expect(scheduler.state == .suspended(phase: .running, remaining: 40))
    scheduler.advance(30)
    #expect(scheduler.state == .suspended(phase: .running, remaining: 40))
    scheduler.handle(.suppression([]))
    #expect(scheduler.state == .running(remaining: 40))
}

@Test func pausingDuringABreakResumesTheBreak() {
    var scheduler = Scheduler(settings: settings)
    scheduler.handle(.takeBreakNow)
    scheduler.handle(.suppression([.locked]))
    scheduler.handle(.suppression([]))
    #expect(scheduler.state == .onBreak(remaining: 10))
}

@Test func lockIsIgnoredWhenTheRuleIsOff() {
    var scheduler = Scheduler(settings: Settings(intervalMinutes: 1, breakSeconds: 10, lockedResponse: .noChange))
    scheduler.handle(.suppression([.locked]))
    scheduler.advance(1)
    #expect(scheduler.state == .running(remaining: 59))
}

@Test(arguments: [Suppression.inCall, .fullscreen])
func suppressionUsesItsConfiguredResponse(reason: Suppression) {
    var scheduler = Scheduler(settings: settings)
    scheduler.handle(.suppression([reason]))
    #expect(scheduler.indicator == .quiet)
    scheduler.handle(.takeBreakNow)
    #expect(scheduler.presentation == .pill(remaining: 10))
    scheduler.handle(.suppression([]))
    #expect(scheduler.presentation == .overlay(remaining: 10))
}

@Test func aPauseResponseTakesPriorityOverPresentationResponses() {
    var scheduler = Scheduler(settings: settings)
    scheduler.handle(.suppression([.locked, .inCall]))
    #expect(scheduler.state == .suspended(phase: .running, remaining: 60))
}

@Test func anOverlayResponseOverridesTheDefaultPillStyle() {
    var scheduler = Scheduler(settings: Settings(intervalMinutes: 1, breakSeconds: 10, style: .pill, fullscreenResponse: .overlay))
    scheduler.handle(.suppression([.fullscreen]))
    scheduler.handle(.takeBreakNow)
    #expect(scheduler.presentation == .overlay(remaining: 10))
}

@Test func aPillResponseWinsWhenAnotherEventAsksForAnOverlay() {
    var scheduler = Scheduler(
        settings: Settings(intervalMinutes: 1, breakSeconds: 10, inCallResponse: .pill, fullscreenResponse: .overlay)
    )
    scheduler.handle(.suppression([.inCall, .fullscreen]))
    scheduler.handle(.takeBreakNow)
    #expect(scheduler.presentation == .pill(remaining: 10))
}

@Test func skipEndsTheBreakAndRestartsTheInterval() {
    var scheduler = Scheduler(settings: settings)
    scheduler.handle(.takeBreakNow)
    scheduler.handle(.skip)
    #expect(scheduler.state == .running(remaining: 60))
    #expect(scheduler.presentation == .none)
}

@Test func pauseHoldsUntilItsDeadlineThenAutoResumes() {
    var scheduler = Scheduler(settings: settings)
    scheduler.advance(20)
    scheduler.handle(.pause(until: epoch.addingTimeInterval(50)))
    scheduler.advance(49)
    #expect(scheduler.state == .paused(remaining: 40, until: epoch.addingTimeInterval(50)))
    scheduler.advance(51)
    #expect(scheduler.state == .running(remaining: 40))
}

@Test func resumeLeavesAPauseEarly() {
    var scheduler = Scheduler(settings: settings)
    scheduler.advance(20)
    scheduler.handle(.pause(until: .distantFuture))
    scheduler.handle(.resume)
    #expect(scheduler.state == .running(remaining: 40))
}

@Test func shorteningTheIntervalClampsTheCountdown() {
    var scheduler = Scheduler(settings: settings)
    #expect(scheduler.remaining == 60)
    scheduler.handle(.settings(Settings(intervalMinutes: 1, breakSeconds: 5)))
    scheduler.handle(.takeBreakNow)
    #expect(scheduler.state == .onBreak(remaining: 5))
}

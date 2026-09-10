import Foundation
import Testing
@testable import BlinkCore

private let epoch = Date(timeIntervalSince1970: 0)

private extension Scheduler {
    mutating func advance(_ seconds: Int, idle: Int = 0) {
        for second in 0..<seconds {
            handle(.tick(now: epoch.addingTimeInterval(Double(second)), idleSeconds: idle))
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

@Test func idleLongerThanBreakRestartsTheInterval() {
    var scheduler = Scheduler(settings: settings)
    scheduler.advance(30)
    scheduler.advance(1, idle: 10)
    #expect(scheduler.state == .running(remaining: 60))
}

@Test func idleShorterThanBreakDoesNotCount() {
    var scheduler = Scheduler(settings: settings)
    scheduler.advance(1, idle: 9)
    #expect(scheduler.state == .running(remaining: 59))
}

@Test func idleIsIgnoredWhenTheRuleIsOff() {
    var scheduler = Scheduler(settings: Settings(intervalMinutes: 1, breakSeconds: 10, idleCountsAsBreak: false))
    scheduler.advance(1, idle: 600)
    #expect(scheduler.state == .running(remaining: 59))
}

@Test func lockSuspendsAndUnlockResumesWhereItLeftOff() {
    var scheduler = Scheduler(settings: settings)
    scheduler.advance(20)
    scheduler.handle(.suppression([.locked]))
    #expect(scheduler.state == .suspended(remaining: 40))
    scheduler.advance(30)
    #expect(scheduler.state == .suspended(remaining: 40))
    scheduler.handle(.suppression([]))
    #expect(scheduler.state == .running(remaining: 40))
}

@Test func lockingDuringABreakCountsItAsTaken() {
    var scheduler = Scheduler(settings: settings)
    scheduler.handle(.takeBreakNow)
    scheduler.handle(.suppression([.locked]))
    scheduler.handle(.suppression([]))
    #expect(scheduler.state == .running(remaining: 60))
}

@Test func lockIsIgnoredWhenTheRuleIsOff() {
    var scheduler = Scheduler(settings: Settings(intervalMinutes: 1, breakSeconds: 10, pauseWhenLocked: false))
    scheduler.handle(.suppression([.locked]))
    scheduler.advance(1)
    #expect(scheduler.state == .running(remaining: 59))
}

@Test(arguments: [Suppression.inCall, .fullscreen])
func suppressionDowngradesTheOverlayToAPill(reason: Suppression) {
    var scheduler = Scheduler(settings: settings)
    scheduler.handle(.suppression([reason]))
    #expect(scheduler.indicator == .quiet)
    scheduler.handle(.takeBreakNow)
    #expect(scheduler.presentation == .pill(remaining: 10))
    scheduler.handle(.suppression([]))
    #expect(scheduler.presentation == .overlay(remaining: 10))
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

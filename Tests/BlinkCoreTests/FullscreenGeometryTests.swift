import CoreGraphics
import Testing
@testable import BlinkCore

/// Captured from a 1728x1117 primary display with a 33pt menu bar and a 78pt Dock.
private let display = CGRect(x: 0, y: 0, width: 1728, height: 1117)
private let menuBar: CGFloat = 33

private func covers(_ window: CGRect) -> Bool {
    FullscreenGeometry.covers(display: display, menuBar: menuBar, window: window)
}

@Test func fullscreenBelowAVisibleMenuBarCovers() {
    #expect(covers(CGRect(x: 0, y: 33, width: 1728, height: 1084)))
}

@Test func fullscreenWithAHiddenMenuBarCovers() {
    #expect(covers(CGRect(x: 0, y: 0, width: 1728, height: 1117)))
}

@Test func aZoomedWindowStopsAboveTheDock() {
    #expect(!covers(CGRect(x: 0, y: 33, width: 1728, height: 1006)))
}

@Test func browserBarsParkedOffscreenDoNotCover() {
    #expect(!covers(CGRect(x: 0, y: -73, width: 1728, height: 41)))
    #expect(!covers(CGRect(x: 0, y: -113, width: 1728, height: 81)))
}

@Test func aTabStripDoesNotCover() {
    #expect(!covers(CGRect(x: 0, y: 33, width: 1728, height: 149)))
}

@Test func anInsetWindowDoesNotCover() {
    #expect(!covers(CGRect(x: 21, y: 69, width: 1728, height: 1048)))
}

@Test func aWindowOnAnotherSpaceDoesNotCover() {
    #expect(!covers(CGRect(x: -1771, y: 33, width: 1728, height: 1006)))
}

@Test func aWindowStartingBelowTheMenuBarDoesNotCover() {
    #expect(!covers(CGRect(x: 0, y: 40, width: 1728, height: 1077)))
}

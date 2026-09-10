extension Int {
    var clock: String { String(format: "%d:%02d", self / 60, self % 60) }
}

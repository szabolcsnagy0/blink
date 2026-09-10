import Observation

@Observable
@MainActor
final class BreakState {
    var remaining = 0
    var total = 1

    var progress: Double { total > 0 ? Double(remaining) / Double(total) : 0 }
}

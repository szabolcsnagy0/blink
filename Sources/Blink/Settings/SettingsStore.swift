import BlinkCore
import Foundation
import Observation

@Observable
@MainActor
final class SettingsStore {
    var settings: Settings {
        didSet {
            guard settings != oldValue else { return }
            settings.save(to: .standard)
            onChange?(settings)
        }
    }

    @ObservationIgnored var onChange: ((Settings) -> Void)?

    init() {
        settings = Settings.load(from: .standard)
    }
}

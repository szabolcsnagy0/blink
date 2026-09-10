import BlinkCore
import SwiftUI

struct SettingsView: View {
    @Bindable var store: SettingsStore

    var body: some View {
        Form {
            Section("Timing") {
                Stepper(value: $store.settings.intervalMinutes, in: 1...180) {
                    LabeledContent("Break every", value: "\(store.settings.intervalMinutes) min")
                }
                Stepper(value: $store.settings.breakSeconds, in: 5...600, step: 5) {
                    LabeledContent("Break length", value: "\(store.settings.breakSeconds) s")
                }
            }

            Section("Appearance") {
                Picker("Style", selection: $store.settings.style) {
                    Text("Overlay").tag(BreakStyle.overlay)
                    Text("Pill").tag(BreakStyle.pill)
                }
                .pickerStyle(.segmented)
                Toggle("Show countdown in menu bar", isOn: $store.settings.showCountdown)
            }

            Section("Pause the timer when") {
                Toggle("The screen is locked", isOn: $store.settings.pauseWhenLocked)
                Toggle("You have been idle longer than a break", isOn: $store.settings.idleCountsAsBreak)
            }

            Section("Show a pill instead of the overlay when") {
                Toggle("The camera or microphone is in use", isOn: $store.settings.pillDuringCalls)
                Toggle("The frontmost app is fullscreen", isOn: $store.settings.pillDuringFullscreen)
            }

            Section {
                Toggle("Launch at login", isOn: Binding(get: { LoginItem.isEnabled }, set: { LoginItem.isEnabled = $0 }))
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
    }
}

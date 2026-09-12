import BlinkCore
import SwiftUI

struct SettingsView: View {
    @Bindable var store: SettingsStore

    var body: some View {
        Form {
            Section("Timing") {
                LabeledContent("Break every") {
                    HStack(spacing: 6) {
                        TextField("Minutes", value: $store.settings.intervalMinutes, formatter: Self.intervalFormatter)
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 56)
                        Stepper("Break every", value: $store.settings.intervalMinutes, in: 1...180)
                            .labelsHidden()
                        Text("minutes")
                            .foregroundStyle(.secondary)
                    }
                }
                LabeledContent("Break length") {
                    HStack(spacing: 6) {
                        TextField("Seconds", value: $store.settings.breakSeconds, formatter: Self.breakFormatter)
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 56)
                        Stepper("Break length", value: $store.settings.breakSeconds, in: 5...600, step: 5)
                            .labelsHidden()
                        Text("seconds")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Appearance") {
                Picker("Style", selection: $store.settings.style) {
                    Text("Overlay").tag(BreakStyle.overlay)
                    Text("Pill").tag(BreakStyle.pill)
                }
                Toggle("Show countdown in menu bar", isOn: $store.settings.showCountdown)
            }

            Section("When these events occur") {
                ForEach(Suppression.allCases, id: \.self) { suppression in
                    Picker(suppression.label, selection: responseBinding(for: suppression)) {
                        ForEach(EventResponse.allCases, id: \.self) { response in
                            Text(response.label).tag(response)
                        }
                    }
                }
            }

            Section("Chrome") {
                Toggle("Pause fullscreen video during overlays", isOn: $store.settings.pauseChromeVideoDuringOverlay)
                    .onChange(of: store.settings.pauseChromeVideoDuringOverlay) { _, enabled in
                        if enabled { Accessibility.requestPermission() }
                    }
            }

            Section {
                Toggle("Launch at login", isOn: Binding(get: { LoginItem.isEnabled }, set: { LoginItem.isEnabled = $0 }))
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
    }

    private func responseBinding(for suppression: Suppression) -> Binding<EventResponse> {
        Binding(
            get: { store.settings.response(for: suppression) },
            set: { response in
                switch suppression {
                case .locked: store.settings.lockedResponse = response
                case .inCall: store.settings.inCallResponse = response
                case .fullscreen: store.settings.fullscreenResponse = response
                }
            }
        )
    }

    private static let intervalFormatter = numberFormatter(minimum: 1, maximum: 180)
    private static let breakFormatter = numberFormatter(minimum: 5, maximum: 600)

    private static func numberFormatter(minimum: Int, maximum: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.allowsFloats = false
        formatter.minimum = minimum as NSNumber
        formatter.maximum = maximum as NSNumber
        return formatter
    }
}

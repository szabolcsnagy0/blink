import SwiftUI

struct PillView: View {
    let state: BreakState
    let onSkip: () -> Void

    var body: some View {
        Button(action: onSkip) {
            HStack(spacing: 10) {
                CountdownRing(progress: state.progress, lineWidth: 2, tint: .primary)
                    .frame(width: 15, height: 15)
                Text("Look away")
                    .font(.system(size: 13, weight: .medium))
                Text(state.remaining.clock)
                    .font(.system(size: 13))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Text("Skip")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(.regularMaterial))
            .overlay(Capsule().strokeBorder(.primary.opacity(0.08)))
            .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
            .padding(8)
        }
        .buttonStyle(.plain)
    }
}

import SwiftUI

struct OverlayView: View {
    let state: BreakState
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea()
            VStack(spacing: 44) {
                ZStack {
                    CountdownRing(progress: state.progress, lineWidth: 3)
                    Text("\(state.remaining)")
                        .font(.system(size: 46, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                .frame(width: 148, height: 148)

                Text("Look at something far away")
                    .font(.system(size: 27, weight: .regular))
                    .foregroundStyle(.white.opacity(0.92))

                VStack(spacing: 12) {
                    Button("Skip", action: onSkip).buttonStyle(SkipButtonStyle())
                    Text("or press esc")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
        }
    }
}

private struct SkipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 22)
            .padding(.vertical, 9)
            .background(Capsule().fill(.white.opacity(configuration.isPressed ? 0.24 : 0.12)))
    }
}

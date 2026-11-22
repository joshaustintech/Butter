import SwiftUI

/// Shows that Butter is listening, or that the session is paused.
struct ListeningIndicator: View {
    let isPaused: Bool

    var body: some View {
        Label(isPaused ? "Paused" : "Listening",
              systemImage: isPaused ? "pause.fill" : "waveform")
            .font(.subheadline)
            .foregroundStyle(Color.butterLabelSecondary)
            .accessibilityLabel(isPaused ? "Paused" : "Listening")
    }
}

#Preview("Light") {
    VStack(spacing: ButterSpacing.lg) {
        ListeningIndicator(isPaused: false)
        ListeningIndicator(isPaused: true)
    }
    .padding(ButterSpacing.xl)
    .background(Color.butterBackground)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    VStack(spacing: ButterSpacing.lg) {
        ListeningIndicator(isPaused: false)
        ListeningIndicator(isPaused: true)
    }
    .padding(ButterSpacing.xl)
    .background(Color.butterBackground)
    .preferredColorScheme(.dark)
}

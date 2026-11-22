import SwiftUI

/// Shows that Butter is listening, or that the session is paused.
struct ListeningIndicator: View {
    let isPaused: Bool

    private var text: String { isPaused ? "Paused" : "Listening" }

    var body: some View {
        Label(text,
              systemImage: isPaused ? "pause.fill" : "waveform")
            .font(.subheadline)
            .foregroundStyle(Color.butterLabelSecondary)
            .onChange(of: isPaused) {
                AccessibilityNotification.Announcement(text).post()
            }
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

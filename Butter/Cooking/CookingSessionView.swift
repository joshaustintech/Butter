import SwiftUI

/// Hands-free Cooking session screen. Shows one Step at a time; the
/// coordinator does the speaking and listening. Not wired into navigation yet.
struct CookingSessionView: View {
    let steps: [String]
    let coordinator: CookingSessionCoordinator
    /// Called from the finished state's Done button.
    var onDone: () -> Void = {}

    @Environment(\.scenePhase) private var scenePhase

    private var currentStep: String {
        let index = coordinator.progress.index
        return steps.indices.contains(index) ? steps[index] : ""
    }

    var body: some View {
        ZStack {
            Color.butterBackground.ignoresSafeArea()
            if coordinator.state == .finished {
                finishedView
            } else {
                sessionView
            }
        }
        .onAppear { coordinator.start() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background: coordinator.pause()
            case .active: coordinator.resume()
            default: break
            }
        }
    }

    private var sessionView: some View {
        VStack(alignment: .leading, spacing: ButterSpacing.xl) {
            HStack {
                Text(coordinator.progress.positionDescription)
                    .font(.headline)
                    .foregroundStyle(Color.butterLabelSecondary)
                Spacer()
                Button("Stop", systemImage: "stop.fill") { coordinator.perform(.stop) }
                    .buttonStyle(.butterSecondary)
                    .fixedSize()
            }

            ScrollView {
                Text(currentStep)
                    .font(.title)
                    .foregroundStyle(Color.butterLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(ButterSpacing.xl)
                    .butterCard()
            }

            if coordinator.isHandsFreeAvailable {
                Label("Listening", systemImage: "waveform")
                    .font(.subheadline)
                    .foregroundStyle(Color.butterLabelSecondary)
                    .opacity(coordinator.state == .paused ? 0.5 : 1)
                    .accessibilityLabel(coordinator.state == .paused ? "Paused" : "Listening")
            }

            controls
        }
        .padding(ButterSpacing.xl)
    }

    private var controls: some View {
        VStack(spacing: ButterSpacing.sm) {
            Button(coordinator.progress.isLast ? "Finish" : "Next",
                   systemImage: coordinator.progress.isLast ? "checkmark" : "forward.fill") {
                coordinator.perform(.next)
            }
            .buttonStyle(.butterPrimary)

            HStack(spacing: ButterSpacing.sm) {
                Button("Back", systemImage: "backward.fill") { coordinator.perform(.back) }
                    .buttonStyle(.butterSecondary)
                    .disabled(coordinator.progress.isFirst)
                Button("Repeat", systemImage: "arrow.counterclockwise") { coordinator.perform(.repeatStep) }
                    .buttonStyle(.butterSecondary)
            }
        }
    }

    private var finishedView: some View {
        VStack(spacing: ButterSpacing.xl) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.butterAccent)
                .accessibilityHidden(true)
            Text("All done")
                .font(.butterDisplay(.largeTitle))
                .foregroundStyle(Color.butterLabel)
            Text("Enjoy your meal.")
                .font(.body)
                .foregroundStyle(Color.butterLabelSecondary)
            Spacer()
            Button("Done", action: onDone)
                .buttonStyle(.butterPrimary)
        }
        .padding(ButterSpacing.xl)
    }
}

#if DEBUG
private final class PreviewSynthesizer: SpeechSynthesizing {
    func speak(_ text: String) async {}
    func stop() {}
}

private final class PreviewListener: CommandListening {
    let transcripts = AsyncStream<String> { _ in }
    func start() async throws {}
    func stop() async {}
    func shutdown() async {}
}

private final class PreviewAudioSession: AudioSessionControlling {
    var onInterruptionEnded: (@MainActor () -> Void)?
    func prepareForListening() throws {}
    func beginSpeaking() throws {}
    func endSpeaking() throws {}
    func deactivate() {}
}

private let previewSteps = [
    "Melt the butter in a wide pan over medium heat until it foams.",
    "Add the sage leaves and cook until crisp, about two minutes.",
    "Toss with the cooked gnocchi and finish with lemon zest.",
]

@MainActor
private func previewCoordinator() -> CookingSessionCoordinator {
    CookingSessionCoordinator(
        steps: previewSteps, synthesizer: PreviewSynthesizer(), listener: PreviewListener(),
        audioSession: PreviewAudioSession(), setIdleTimerDisabled: { _ in })!
}

#Preview("Light") {
    CookingSessionView(steps: previewSteps, coordinator: previewCoordinator())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    CookingSessionView(steps: previewSteps, coordinator: previewCoordinator())
        .preferredColorScheme(.dark)
}
#endif

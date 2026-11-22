import SwiftUI

/// Hands-free Cooking session screen. Shows one Step at a time; the
/// coordinator does the speaking and listening. Not wired into navigation yet.
struct CookingSessionView: View {
    let coordinator: CookingSessionCoordinator
    /// Called from the finished state's Done button.
    var onDone: () -> Void = {}

    @Environment(\.scenePhase) private var scenePhase

    private var isPaused: Bool { coordinator.state == .paused }

    var body: some View {
        ZStack {
            Color.butterBackground.ignoresSafeArea()
            if coordinator.state == .finished {
                CookingFinishedView(onDone: onDone)
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
                Spacer()
                Button("Stop", systemImage: "stop.fill") { coordinator.perform(.stop) }
                    .buttonStyle(.butterSecondary)
                    .fixedSize()
            }

            CookingStepCard(position: coordinator.progress.positionDescription, text: coordinator.currentStep)

            if coordinator.isHandsFreeAvailable || isPaused {
                ListeningIndicator(isPaused: isPaused)
                    .opacity(isPaused ? 0.5 : 1)
            }

            CookingControls(
                isFirst: coordinator.progress.isFirst,
                isLast: coordinator.progress.isLast,
                onNext: { coordinator.perform(.next) },
                onBack: { coordinator.perform(.back) },
                onRepeat: { coordinator.perform(.repeatStep) })
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
    var fails = false
    func start() async throws { if fails { throw CommandListeningError.microphoneDenied } }
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

private enum PreviewState { case first, middle, last, paused, handsFreeUnavailable, finished }

/// Builds a coordinator that has already reached `state`, using fake adapters.
@MainActor
private func previewCoordinator(_ state: PreviewState) -> CookingSessionCoordinator {
    let listener = PreviewListener()
    listener.fails = state == .handsFreeUnavailable
    let coordinator = CookingSessionCoordinator(
        steps: previewSteps, synthesizer: PreviewSynthesizer(), listener: listener,
        audioSession: PreviewAudioSession(), setIdleTimerDisabled: { _ in })!
    coordinator.start()
    switch state {
    case .first, .handsFreeUnavailable: break
    case .middle: coordinator.perform(.next)
    case .last: coordinator.perform(.next); coordinator.perform(.next)
    case .paused: coordinator.pause()
    case .finished: coordinator.perform(.stop)
    }
    return coordinator
}

#Preview("First Step, light") {
    CookingSessionView(coordinator: previewCoordinator(.first)).preferredColorScheme(.light)
}
#Preview("First Step, dark") {
    CookingSessionView(coordinator: previewCoordinator(.first)).preferredColorScheme(.dark)
}
#Preview("Middle Step, light") {
    CookingSessionView(coordinator: previewCoordinator(.middle)).preferredColorScheme(.light)
}
#Preview("Middle Step, dark") {
    CookingSessionView(coordinator: previewCoordinator(.middle)).preferredColorScheme(.dark)
}
#Preview("Last Step, light") {
    CookingSessionView(coordinator: previewCoordinator(.last)).preferredColorScheme(.light)
}
#Preview("Last Step, dark") {
    CookingSessionView(coordinator: previewCoordinator(.last)).preferredColorScheme(.dark)
}
#Preview("Paused, light") {
    CookingSessionView(coordinator: previewCoordinator(.paused)).preferredColorScheme(.light)
}
#Preview("Paused, dark") {
    CookingSessionView(coordinator: previewCoordinator(.paused)).preferredColorScheme(.dark)
}
#Preview("Hands-free unavailable, light") {
    CookingSessionView(coordinator: previewCoordinator(.handsFreeUnavailable)).preferredColorScheme(.light)
}
#Preview("Hands-free unavailable, dark") {
    CookingSessionView(coordinator: previewCoordinator(.handsFreeUnavailable)).preferredColorScheme(.dark)
}
#Preview("Finished, light") {
    CookingSessionView(coordinator: previewCoordinator(.finished)).preferredColorScheme(.light)
}
#Preview("Finished, dark") {
    CookingSessionView(coordinator: previewCoordinator(.finished)).preferredColorScheme(.dark)
}
#endif

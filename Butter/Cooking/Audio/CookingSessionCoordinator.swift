import Observation
import UIKit

/// Runs a hands-free Cooking session: speaks one Step at a time, listens for
/// commands between Steps, and keeps the screen awake. Foreground only.
///
/// Half-duplex: the listener is stopped while a Step is spoken and resumes a
/// short delay after, so Butter never hears itself. Spoken Steps are the only
/// time other audio is ducked.
@MainActor @Observable
final class CookingSessionCoordinator {
    enum State: Equatable {
        case idle, speaking, listening, paused, finished
    }

    private(set) var state: State = .idle
    private(set) var progress: CookingProgress
    private(set) var lastHeard: String?
    /// False when the listener could not start; buttons and Siri still work.
    private(set) var isHandsFreeAvailable = true

    /// The text of the Step the session is on.
    var currentStep: String { steps[progress.index] }

    @ObservationIgnored private let steps: [String]
    @ObservationIgnored private let synthesizer: any SpeechSynthesizing
    @ObservationIgnored private let listener: any CommandListening
    @ObservationIgnored private let audioSession: any AudioSessionControlling
    @ObservationIgnored private let setIdleTimerDisabled: (Bool) -> Void
    @ObservationIgnored private let resumeDelay: Duration
    @ObservationIgnored private var speakTask: Task<Void, Never>?
    @ObservationIgnored private var transcriptTask: Task<Void, Never>?

    /// Returns `nil` when there are no Steps.
    init?(
        steps: [String],
        synthesizer: any SpeechSynthesizing,
        listener: any CommandListening,
        audioSession: any AudioSessionControlling,
        resumeDelay: Duration = .milliseconds(250),
        setIdleTimerDisabled: @escaping (Bool) -> Void = { UIApplication.shared.isIdleTimerDisabled = $0 }
    ) {
        guard let progress = CookingProgress(stepCount: steps.count) else { return nil }
        self.progress = progress
        self.steps = steps
        self.synthesizer = synthesizer
        self.listener = listener
        self.audioSession = audioSession
        self.resumeDelay = resumeDelay
        self.setIdleTimerDisabled = setIdleTimerDisabled
    }

    /// Begins the session on the first Step.
    func start() {
        guard state == .idle else { return }
        setIdleTimerDisabled(true)
        audioSession.onInterruptionEnded = { [weak self] in self?.resume() }
        transcriptTask = Task { [weak self, listener] in
            for await transcript in listener.transcripts {
                guard !Task.isCancelled else { return }
                self?.heard(transcript)
            }
        }
        speakCurrentStep()
    }

    /// Applies a command from voice, a button or Siri.
    func perform(_ command: CookingCommand) {
        guard state != .idle, state != .finished else { return }
        switch command {
        case .next:
            if progress.advance() == .finished { finish() } else { speakCurrentStep() }
        case .back:
            progress.goBack()
            speakCurrentStep()
        case .repeatStep:
            speakCurrentStep()
        case .stop:
            finish()
        }
    }

    /// Lock or background: stop everything but keep the position.
    func pause() {
        guard state == .speaking || state == .listening else { return }
        interrupt()
        Task { await listener.stop() }
        audioSession.deactivate()
        state = .paused
    }

    /// Foreground again (or Siri interruption ended): listen for commands.
    func resume() {
        guard state == .paused else { return }
        startListening()
    }

    private func heard(_ transcript: String) {
        guard state == .listening else { return }
        lastHeard = transcript
        if let command = CookingCommand.parse(transcript: transcript) { perform(command) }
    }

    private func speakCurrentStep() {
        interrupt()
        let text = currentStep
        state = .speaking
        speakTask = Task { [weak self] in
            guard let self else { return }
            await listener.stop()
            guard !Task.isCancelled else { return }
            try? audioSession.beginSpeaking()
            await synthesizer.speak(text)
            guard !Task.isCancelled else { return }
            try? audioSession.endSpeaking()
            try? await Task.sleep(for: resumeDelay)
            guard !Task.isCancelled else { return }
            startListening()
        }
    }

    private func startListening() {
        speakTask = Task { [weak self] in
            guard let self else { return }
            do {
                try audioSession.prepareForListening()
                try await listener.start()
                guard !Task.isCancelled else { return }
                isHandsFreeAvailable = true
                state = .listening
            } catch {
                isHandsFreeAvailable = false
                state = .listening
            }
        }
    }

    private func interrupt() {
        speakTask?.cancel()
        speakTask = nil
        synthesizer.stop()
    }

    private func finish() {
        interrupt()
        transcriptTask?.cancel()
        transcriptTask = nil
        state = .finished
        setIdleTimerDisabled(false)
        Task { [listener, audioSession] in
            await listener.shutdown()
            audioSession.deactivate()
        }
    }
}

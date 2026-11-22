import AVFoundation

/// Reads one Step aloud. Implementations speak a single Step's text at a time.
protocol SpeechSynthesizing: AnyObject {
    /// Speaks `text` and returns when it finishes or is stopped.
    func speak(_ text: String) async
    /// Stops speaking immediately. A pending `speak` returns.
    func stop()
}

/// `AVSpeechSynthesizer` speaker using the best installed voice for the locale.
final class SystemSpeechSynthesizer: NSObject, SpeechSynthesizing, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private let locale: Locale
    private var continuation: CheckedContinuation<Void, Never>?

    init(locale: Locale = .current) {
        self.locale = locale
        super.init()
        synthesizer.delegate = self
        // Follow the cook's Spoken Content / VoiceOver rate and voice settings.
        synthesizer.usesApplicationAudioSession = true
    }

    func speak(_ text: String) async {
        stop()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = Self.bestVoice(for: locale)
        utterance.prefersAssistiveTechnologySettings = true
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            synthesizer.speak(utterance)
        }
    }

    func stop() {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        resume()
    }

    private func resume() {
        continuation?.resume()
        continuation = nil
    }

    /// Premium, then enhanced, then default quality for the locale's language.
    static func bestVoice(for locale: Locale) -> AVSpeechSynthesisVoice? {
        let language = locale.identifier(.bcp47)
        let prefix = locale.language.languageCode?.identifier ?? language
        let voices = AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language == language || $0.language.hasPrefix(prefix)
        }
        let exact = voices.filter { $0.language == language }
        let pool = exact.isEmpty ? voices : exact
        return pool.max { $0.quality.rawValue < $1.quality.rawValue }
            ?? AVSpeechSynthesisVoice(language: language)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        MainActor.assumeIsolated { resume() }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        MainActor.assumeIsolated { resume() }
    }
}

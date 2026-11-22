import AVFoundation
import Speech

/// Listens on the device and emits what the cook says.
protocol CommandListening: AnyObject {
    /// Transcripts (volatile and final). Lives for the listener's lifetime
    /// across `start`/`stop` pairs, and finishes on `shutdown()`.
    var transcripts: AsyncStream<String> { get }
    /// Begins capturing. Throws when permission, locale or assets are missing.
    func start() async throws
    /// Stops capturing but keeps `transcripts` open.
    func stop() async
    /// Stops and finishes `transcripts`.
    func shutdown() async
}

enum CommandListeningError: Error, Equatable {
    case microphoneDenied
    case unsupportedLocale
    case noInputFormat
}

/// `SpeechAnalyzer` listener. Baseline module is `DictationTranscriber`, which
/// covers every device with on-device dictation (iPhone 15 included).
/// `SpeechTranscriber` is used only when asked for and `isAvailable`.
final class SpeechAnalyzerCommandListener: CommandListening {
    let transcripts: AsyncStream<String>
    private let transcriptContinuation: AsyncStream<String>.Continuation

    private let locale: Locale
    private let prefersSpeechTranscriber: Bool
    private let engine = AVAudioEngine()
    private var analyzer: SpeechAnalyzer?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    private var resultsTask: Task<Void, Never>?
    private var isRunning = false

    init(locale: Locale = .current, prefersSpeechTranscriber: Bool = false) {
        self.locale = locale
        self.prefersSpeechTranscriber = prefersSpeechTranscriber
        (transcripts, transcriptContinuation) = AsyncStream.makeStream(of: String.self)
    }

    func start() async throws {
        guard !isRunning else { return }
        guard await AVAudioApplication.requestRecordPermission() else {
            throw CommandListeningError.microphoneDenied
        }

        let module: any SpeechModule
        let results: @Sendable () async -> Void
        let sink = transcriptContinuation
        if prefersSpeechTranscriber, SpeechTranscriber.isAvailable,
           await SpeechTranscriber.supportedLocale(equivalentTo: locale) != nil {
            let transcriber = SpeechTranscriber(
                locale: locale, transcriptionOptions: [], reportingOptions: [.volatileResults], attributeOptions: [])
            module = transcriber
            results = {
                do { for try await r in transcriber.results { sink.yield(String(r.text.characters)) } } catch {}
            }
        } else {
            guard await DictationTranscriber.supportedLocale(equivalentTo: locale) != nil else {
                throw CommandListeningError.unsupportedLocale
            }
            let transcriber = DictationTranscriber(
                locale: locale, contentHints: [.farField, .shortForm],
                transcriptionOptions: [], reportingOptions: [.volatileResults], attributeOptions: [])
            module = transcriber
            results = {
                do { for try await r in transcriber.results { sink.yield(String(r.text.characters)) } } catch {}
            }
        }

        let modules: [any SpeechModule] = [module, SpeechDetector(detectionOptions: .init(sensitivityLevel: .medium), reportResults: false)]
        if let request = try await AssetInventory.assetInstallationRequest(supporting: modules) {
            try await request.downloadAndInstall()
        }
        guard let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: modules) else {
            throw CommandListeningError.noInputFormat
        }

        let analyzer = SpeechAnalyzer(modules: modules)
        try await analyzer.prepareToAnalyze(in: analyzerFormat)
        let (inputs, inputContinuation) = AsyncStream.makeStream(of: AnalyzerInput.self)

        let input = engine.inputNode
        let micFormat = input.outputFormat(forBus: 0)
        guard micFormat.sampleRate > 0, let converter = AVAudioConverter(from: micFormat, to: analyzerFormat) else {
            throw CommandListeningError.noInputFormat
        }
        input.installTap(onBus: 0, bufferSize: 4096, format: micFormat,
                         block: Self.makeTap(converter: converter, format: analyzerFormat, into: inputContinuation))
        engine.prepare()
        try engine.start()

        self.analyzer = analyzer
        self.inputContinuation = inputContinuation
        resultsTask = Task { await results() }
        isRunning = true
        try await analyzer.start(inputSequence: inputs)
    }

    func stop() async {
        guard isRunning else { return }
        isRunning = false
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        inputContinuation?.finish()
        inputContinuation = nil
        await analyzer?.cancelAndFinishNow()
        analyzer = nil
        resultsTask?.cancel()
        resultsTask = nil
    }

    func shutdown() async {
        await stop()
        transcriptContinuation.finish()
    }

    /// Runs on the realtime audio thread, so it must not be MainActor-isolated.
    private nonisolated static func makeTap(
        converter: AVAudioConverter, format: AVAudioFormat, into continuation: AsyncStream<AnalyzerInput>.Continuation
    ) -> @Sendable (AVAudioPCMBuffer, AVAudioTime) -> Void {
        return { buffer, _ in
            let ratio = format.sampleRate / buffer.format.sampleRate
            let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1
            guard let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else { return }
            nonisolated(unsafe) var supplied = false
            nonisolated(unsafe) let source = buffer
            var error: NSError?
            converter.convert(to: out, error: &error) { _, status in
                if supplied { status.pointee = .noDataNow; return nil }
                supplied = true
                status.pointee = .haveData
                return source
            }
            if error == nil, out.frameLength > 0 { continuation.yield(AnalyzerInput(buffer: out)) }
        }
    }
}

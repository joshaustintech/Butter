import AVFoundation

/// The audio session states a Cooking session moves through.
protocol AudioSessionControlling: AnyObject {
    /// Called when a system interruption (for example Siri) ends.
    var onInterruptionEnded: (@MainActor () -> Void)? { get set }
    /// Mixable record-and-play session. Other apps' music is not touched.
    func prepareForListening() throws
    /// Ducks other audio. Call only while a Step is being spoken.
    func beginSpeaking() throws
    /// Releases ducking so other audio returns to full volume.
    func endSpeaking() throws
    /// Gives the session back entirely.
    func deactivate()
}

/// Configures `AVAudioSession` for hands-free cooking.
///
/// Ducking follows session activation, so each Step deactivates, adds
/// `duckOthers`, reactivates, and on finish deactivates with
/// `notifyOthersOnDeactivation` so music swells back. The session must never be
/// activated without `mixWithOthers`, or other apps' music is interrupted.
/// The caller must stop the audio engine before `beginSpeaking`/`endSpeaking`
/// (deactivating while it runs fails with `isBusy`); the coordinator does.
final class AudioSessionController: AudioSessionControlling {
    var onInterruptionEnded: (@MainActor () -> Void)?

    private let session = AVAudioSession.sharedInstance()
    nonisolated(unsafe) private var observer: (any NSObjectProtocol)?

    static let listeningOptions: AVAudioSession.CategoryOptions =
        [.mixWithOthers, .defaultToSpeaker, .allowBluetoothA2DP]
    static let speakingOptions: AVAudioSession.CategoryOptions =
        listeningOptions.union([.duckOthers, .interruptSpokenAudioAndMixWithOthers])

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
        ) { [weak self] note in
            let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            guard raw.flatMap(AVAudioSession.InterruptionType.init(rawValue:)) == .ended else { return }
            MainActor.assumeIsolated { self?.onInterruptionEnded?() }
        }
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    func prepareForListening() throws {
        try session.setCategory(.playAndRecord, mode: .default, options: Self.listeningOptions)
        try session.setActive(true)
    }

    func beginSpeaking() throws {
        try session.setActive(false, options: .notifyOthersOnDeactivation)
        try session.setCategory(.playAndRecord, mode: .default, options: Self.speakingOptions)
        try session.setActive(true)
    }

    func endSpeaking() throws {
        try session.setActive(false, options: .notifyOthersOnDeactivation)
        try prepareForListening()
    }

    func deactivate() {
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }
}

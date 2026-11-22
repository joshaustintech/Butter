import Testing
@testable import Butter

@MainActor
private final class Log {
    var events: [String] = []
}

private final class FakeSynthesizer: SpeechSynthesizing {
    let log: Log
    init(_ log: Log) { self.log = log }
    func speak(_ text: String) async { log.events.append("speak:\(text)") }
    func stop() { log.events.append("synth.stop") }
}

private final class FakeListener: CommandListening {
    let log: Log
    let transcripts: AsyncStream<String>
    let continuation: AsyncStream<String>.Continuation
    var failStart = false
    init(_ log: Log) {
        self.log = log
        (transcripts, continuation) = AsyncStream.makeStream(of: String.self)
    }
    func start() async throws {
        if failStart { throw CommandListeningError.microphoneDenied }
        log.events.append("listen.start")
    }
    func stop() async { log.events.append("listen.stop") }
    func shutdown() async { log.events.append("listen.shutdown"); continuation.finish() }
}

private final class FakeAudioSession: AudioSessionControlling {
    let log: Log
    var onInterruptionEnded: (@MainActor () -> Void)?
    init(_ log: Log) { self.log = log }
    func prepareForListening() throws { log.events.append("audio.listening") }
    func beginSpeaking() throws { log.events.append("audio.duck") }
    func endSpeaking() throws { log.events.append("audio.unduck"); log.events.append("audio.listening") }
    func deactivate() { log.events.append("audio.deactivate") }
}

@MainActor
private struct Rig {
    let log = Log()
    let listener: FakeListener
    let coordinator: CookingSessionCoordinator
    let audio: FakeAudioSession
    var idle: [Bool] { idleBox.values }
    let idleBox = IdleBox()

    init(steps: [String] = ["one", "two", "three"]) {
        listener = FakeListener(log)
        audio = FakeAudioSession(log)
        let box = idleBox
        coordinator = CookingSessionCoordinator(
            steps: steps, synthesizer: FakeSynthesizer(log), listener: listener, audioSession: audio,
            resumeDelay: .milliseconds(1), setIdleTimerDisabled: { box.values.append($0) })!
    }

    func waitUntil(_ state: CookingSessionCoordinator.State) async {
        for _ in 0..<500 where coordinator.state != state { try? await Task.sleep(for: .milliseconds(2)) }
    }
}

@MainActor private final class IdleBox { var values: [Bool] = [] }

@MainActor
struct CookingSessionCoordinatorTests {
    @Test func rejectsEmptySteps() {
        let log = Log()
        #expect(CookingSessionCoordinator(steps: [], synthesizer: FakeSynthesizer(log),
                                          listener: FakeListener(log), audioSession: FakeAudioSession(log)) == nil)
    }

    @Test func speaksFirstStepHalfDuplexThenListens() async {
        let rig = Rig()
        rig.coordinator.start()
        await rig.waitUntil(.listening)
        #expect(rig.log.events == ["synth.stop", "listen.stop", "audio.duck", "speak:one", "audio.unduck", "audio.listening", "audio.listening", "listen.start"])
        #expect(rig.idle == [true])
    }

    @Test func heardNextSpeaksNextStep() async {
        let rig = Rig()
        rig.coordinator.start()
        await rig.waitUntil(.listening)
        rig.log.events.removeAll()
        rig.listener.continuation.yield("okay next step")
        await rig.waitUntil(.speaking)
        await rig.waitUntil(.listening)
        #expect(rig.coordinator.progress.index == 1)
        #expect(rig.log.events.contains("speak:two"))
    }

    @Test func unrelatedSpeechIsIgnored() async {
        let rig = Rig()
        rig.coordinator.start()
        await rig.waitUntil(.listening)
        rig.listener.continuation.yield("put it next to the stove")
        try? await Task.sleep(for: .milliseconds(30))
        #expect(rig.coordinator.progress.index == 0)
        #expect(rig.coordinator.state == .listening)
    }

    @Test func backAndRepeatSpeakExpectedSteps() async {
        let rig = Rig()
        rig.coordinator.start()
        await rig.waitUntil(.listening)
        rig.coordinator.perform(.next)
        await rig.waitUntil(.listening)
        rig.log.events.removeAll()
        rig.coordinator.perform(.back)
        await rig.waitUntil(.listening)
        #expect(rig.coordinator.progress.index == 0)
        #expect(rig.log.events.contains("speak:one"))
        rig.log.events.removeAll()
        rig.coordinator.perform(.repeatStep)
        await rig.waitUntil(.listening)
        #expect(rig.log.events.contains("speak:one"))
    }

    @Test func nextOnLastStepFinishesAndReleasesEverything() async {
        let rig = Rig(steps: ["only"])
        rig.coordinator.start()
        await rig.waitUntil(.listening)
        rig.coordinator.perform(.next)
        #expect(rig.coordinator.state == .finished)
        #expect(rig.idle == [true, false])
        try? await Task.sleep(for: .milliseconds(30))
        #expect(rig.log.events.contains("listen.shutdown"))
        #expect(rig.log.events.last == "audio.deactivate")
    }

    @Test func stopCommandFinishes() async {
        let rig = Rig()
        rig.coordinator.start()
        await rig.waitUntil(.listening)
        rig.listener.continuation.yield("stop")
        await rig.waitUntil(.finished)
        #expect(rig.coordinator.state == .finished)
        #expect(rig.idle == [true, false])
    }

    @Test func pauseStopsListeningAndResumeListensWithoutMovingStep() async {
        let rig = Rig()
        rig.coordinator.start()
        await rig.waitUntil(.listening)
        rig.coordinator.pause()
        #expect(rig.coordinator.state == .paused)
        try? await Task.sleep(for: .milliseconds(20))
        #expect(rig.log.events.contains("synth.stop") && rig.log.events.contains("audio.deactivate"))
        rig.log.events.removeAll()
        rig.audio.onInterruptionEnded?()
        await rig.waitUntil(.listening)
        #expect(rig.coordinator.progress.index == 0)
        #expect(rig.log.events == ["audio.listening", "listen.start"])
    }

    @Test func listenerFailureKeepsButtonsWorking() async {
        let rig = Rig()
        rig.listener.failStart = true
        rig.coordinator.start()
        await rig.waitUntil(.listening)
        #expect(!rig.coordinator.isHandsFreeAvailable)
        rig.coordinator.perform(.next)
        #expect(rig.coordinator.progress.index == 1)
    }
}

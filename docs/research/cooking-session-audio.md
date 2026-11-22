# Research: how Butter listens and speaks during a Cooking session

Ticket: [#6](https://github.com/joshaustintech/Butter/issues/6). Feeds decision [#10](https://github.com/joshaustintech/Butter/issues/10). Map: [#2](https://github.com/joshaustintech/Butter/issues/2).

Constraints from the map: iPhone only, iOS 26 minimum, no server, progressive enhancement, target devices iPhone 15 Pro and iPhone 15. Butter turns music down while it speaks but never controls playback.

Researched 2026-11-21 against Apple developer documentation (current SDK, which documents iOS 27), WWDC sessions and the App Review Guidelines. Each claim links to its source. Statements marked **(inference)** or **(unverified)** aren't stated in a primary source and need a device test.

---

## TL;DR

- **Recognizer:** use `SpeechAnalyzer` (iOS 26) with a transcriber module, chosen at runtime. Use `SpeechTranscriber` when `SpeechTranscriber.isAvailable` is true. Otherwise use `DictationTranscriber`, which runs on every device that supports on-device `SFSpeechRecognizer`, and bias it toward the command words with `AnalysisContext.contextualStrings`. Don't build on `SFSpeechRecognizer`: Apple documents a one-minute limit on its tasks, and it falls back to the server for some locales.
- **iPhone 15:** Apple publishes no device list for `SpeechTranscriber` and tells developers to check `isAvailable` at runtime. `DictationTranscriber` covers the iPhone 15 either way, so continuous on-device listening works on both target phones. Only the model behind it may differ.
- **Self-hearing:** go half-duplex. Stop feeding microphone audio to the analyzer while Butter speaks, then resume. Voice processing (echo cancellation) exists, but it ducks other apps' audio for as long as it's enabled, which breaks the music requirement. Treat it as an experiment, not the baseline.
- **Music:** use one `playAndRecord` session with `.mixWithOthers` and `.defaultToSpeaker` (plus `.allowBluetoothA2DP`) while listening. Turn on `.duckOthers` only while a Step is read. Ducking follows session *activation*, so every utterance needs a short reconfigure-and-reactivate sequence (below). Deactivate with `.notifyOthersOnDeactivation`. Apple Music and Spotify don't get to choose how they react: the system ducks them. Spotify's exact behaviour still needs a device test.
- **Voice:** `AVSpeechSynthesizer` with the best installed voice for the locale (`.premium`, then `.enhanced`, then default). Premium and enhanced voices must be downloaded by the user in Settings. Siri voices aren't available to apps.
- **Screen and lock:** set `isIdleTimerDisabled = true` only while a Cooking session is on screen, and reset it afterwards. Don't add the `audio` background mode for v1. If the phone locks, the app is suspended and its audio session deactivated, so pause listening and resume it in the foreground.
- **Siri:** expose next, back, repeat and stop as App Intents that act on the same in-app Cooking session state. A Siri invocation interrupts Butter's audio session, so resume listening when the interruption ends. iOS 27 adds clearer lifecycle notifications for this.

---

## 1. On-device recognition: SpeechAnalyzer vs SFSpeechRecognizer

### SpeechAnalyzer (iOS 26+)

- `SpeechAnalyzer` is available from iOS 26.0. It "analyzes spoken audio content in various ways and manages the analysis session". You add modules to it, and their results arrive as an `AsyncSequence`. "The analyzer can only analyze one input sequence at a time." ([SpeechAnalyzer](https://developer.apple.com/documentation/speech/speechanalyzer))
- The documentation mentions no duration limit. Unless you call a `finish` method, "the analyzer won't terminate its result streams and will wait for additional audio input sequences or buffers". That is the continuous-session model Butter wants. (same source, "Analyze audio from files or capture devices")
- Transcription is fully on device: "Remember that transcription is entirely on device but the models need to be fetched." ([WWDC25 session 277](https://developer.apple.com/videos/play/wwdc2025/277/)) "[SpeechAnalyzer] transcriber modules don't send audio data of the user's voice to Apple's servers." ([Asking Permission to Use Speech Recognition](https://developer.apple.com/documentation/speech/asking-permission-to-use-speech-recognition))
- The models are system assets installed through `AssetInventory`. They're "downloaded from Apple's servers and managed by the system", "persist between app launches and are shared between apps", and "the system may unsubscribe your app from assets that haven't been used in a while". ([AssetInventory](https://developer.apple.com/documentation/speech/assetinventory)) A first Cooking session may therefore need a one-time download. Check `assetInstallationRequest(supporting:)` before the first session, for example at app launch. This uses Apple's servers but isn't a Butter server, so it fits "no server".
- `bestAvailableAudioFormat(compatibleWith:)` returns `nil` "if the specified modules require you to install additional assets". The analyzer "does not transparently upsample, downsample, or convert audio input". ([bestAvailableAudioFormat](https://developer.apple.com/documentation/speech/speechanalyzer/bestavailableaudioformat(compatiblewith:)))
- Latency: `prepareToAnalyze(in:)` "prepares the analyzer to begin work with minimal startup delay" ([docs](https://developer.apple.com/documentation/speech/speechanalyzer/preparetoanalyze(in:))). `ModelRetention` options keep resources loaded between analyzers ([SpeechAnalyzer, "Improve responsiveness"](https://developer.apple.com/documentation/speech/speechanalyzer)). Volatile results are "delivered almost as soon as they're spoken but they are less accurate guesses" ([WWDC25-277](https://developer.apple.com/videos/play/wwdc2025/277/)). `SpeechTranscriber.ReportingOption.fastResults` "biases the transcriber towards responsiveness … by using a smaller 'context window'" ([docs](https://developer.apple.com/documentation/speech/speechtranscriber/reportingoption/fastresults)). For a one-word command, act on a volatile result that matches a command. Don't wait for finalization.
- `SpeechDetector` (voice activity detection) "provides you with the ability to gate transcription by the presence of voices, saving power otherwise used by attempting to transcribe what is likely to be silence". It works only together with `SpeechTranscriber` or `DictationTranscriber`. Apple recommends sensitivity `.medium` and warns that VAD can drop audio that contains speech. ([SpeechDetector](https://developer.apple.com/documentation/speech/speechdetector), [SensitivityLevel](https://developer.apple.com/documentation/speech/speechdetector/sensitivitylevel)) This is the main battery lever for a long Cooking session.
- Permissions: you need microphone permission (`NSMicrophoneUsageDescription`; [requestRecordPermission](https://developer.apple.com/documentation/avfaudio/avaudioapplication/requestrecordpermission(completionhandler:))). The speech-recognition authorization flow "only applies to speech recognition using SFSpeechRecognizer" ([Asking Permission](https://developer.apple.com/documentation/speech/asking-permission-to-use-speech-recognition)).
- Simulator: according to developer forum reports, `SpeechTranscriber` doesn't work in the Simulator ([forum 802863](https://developer.apple.com/forums/thread/802863)). This is a user report, not Apple documentation. Plan to test on a real device.

### The two transcriber modules

| | `SpeechTranscriber` | `DictationTranscriber` |
|---|---|---|
| Purpose | "appropriate for normal conversation and general purposes", good for long-form and distant audio ([docs](https://developer.apple.com/documentation/speech/speechtranscriber), [WWDC25-277](https://developer.apple.com/videos/play/wwdc2025/277/)) | "similar to system dictation features and compatible with older devices" ([docs](https://developer.apple.com/documentation/speech/dictationtranscriber)) |
| Model | New on-device model | "the same speech-to-text machine learning models as system dictation features do, or as SFSpeechRecognizer does when it is configured for on-device operation" |
| Device support | "available for all platforms but watchOS with certain hardware requirements". Check `isAvailable` ("given the device's hardware and capabilities") or `supportedLocales` (empty if the device isn't supported) ([isAvailable](https://developer.apple.com/documentation/speech/speechtranscriber/isavailable), [supportedLocales](https://developer.apple.com/documentation/speech/speechtranscriber/supportedlocales)) | "supports the same languages, speech-to-text model, and devices as iOS 10's on-device SFSpeechRecognizer", with no need for the user to turn on Siri or dictation for the language ([WWDC25-277](https://developer.apple.com/videos/play/wwdc2025/277/)) |
| Vocabulary biasing | Not documented for this module | `AnalysisContext.contextualStrings` ("With the DictationTranscriber module…", short one- or two-word phrases, at most 100), plus custom language models and the `ContentHint` values `.shortForm` and `.farField` ([contextualStrings](https://developer.apple.com/documentation/speech/analysiscontext/contextualstrings), [ContentHint](https://developer.apple.com/documentation/speech/dictationtranscriber/contenthint)) |
| Apple's fallback advice | "If it does not, consider disabling the feature or using DictationTranscriber instead." ([SpeechTranscriber](https://developer.apple.com/documentation/speech/speechtranscriber)) | — |

**iPhone 15 (A16, no Apple Intelligence):** Apple's DTS engineer: "We typically do not publish such lists. Instead, we recommend that you use the isAvailable check at runtime, and design a fallback experience if not available." ([forum 802863](https://developer.apple.com/forums/thread/802863)) Community reports say it works on an iPhone 14 Pro (also an A16) and fails on an iPhone 11 Pro and SE 2nd gen ([forum results](https://developer.apple.com/forums/thread/807739)). **(unverified for iPhone 15)** Either way, `DictationTranscriber` covers it. `SpeechTranscriber` isn't documented as depending on Apple Intelligence, so the 15 Pro / 15 split doesn't decide this **(inference)**.

**Recommendation for the four commands:** `DictationTranscriber` with `contextualStrings = ["next", "back", "repeat", "stop", …]`, the `.farField` hint (the phone sits on the counter), and volatile/progressive reporting may be the *better* default on both phones, because only it supports vocabulary biasing. Run both transcribers on the device and compare false positives with music playing before you pick. Match whole tokens of the volatile text against a small synonym table (next/forward, back/previous/go back, repeat/again/say again, stop/pause). Ignore everything else.

### SFSpeechRecognizer (iOS 10+). Don't use it for this.

- "Plan for a one-minute limit on audio duration … the framework stops speech recognition tasks that last longer than one minute." Per-device and per-app daily limits also apply, because "speech recognition is a network-based service". ([SFSpeechRecognizer](https://developer.apple.com/documentation/speech/sfspeechrecognizer))
- On-device operation only works if `supportsOnDeviceRecognition` is true. Otherwise it "requires a network", and `requiresOnDeviceRecognition` is ignored. ([supportsOnDeviceRecognition](https://developer.apple.com/documentation/speech/sfspeechrecognizer/supportsondevicerecognition), [requiresOnDeviceRecognition](https://developer.apple.com/documentation/speech/sfspeechrecognitionrequest/requiresondevicerecognition))
- `DictationTranscriber` is Apple's stated replacement for the same model and devices. Because Butter's minimum is iOS 26, `SFSpeechRecognizer` adds nothing.

### iOS 26 vs iOS 27

- **iOS 26:** `SpeechAnalyzer`, `SpeechTranscriber`, `DictationTranscriber`, `SpeechDetector`, `AssetInventory` and `AnalysisContext` exist. You feed microphone audio yourself: tap `AVAudioEngine.inputNode`, convert the buffers to `bestAvailableAudioFormat` (for example with `AVAudioConverter`), and yield them as `AnalyzerInput` into an `AsyncStream` (pattern in [WWDC25-277](https://developer.apple.com/videos/play/wwdc2025/277/)).
- **iOS 27 (June 2026 Speech updates):** adds `CaptureInputSequenceProvider` (reads from a capture device such as a microphone), `AssetInputSequenceProvider` and `AnalyzerInputConverter` (converts `AVAudioBuffer` audio to `AnalyzerInput`). All three are iOS 27.0+. ([Speech updates](https://developer.apple.com/documentation/updates/speech), [CaptureInputSequenceProvider](https://developer.apple.com/documentation/speech/captureinputsequenceprovider), [AnalyzerInputConverter](https://developer.apple.com/documentation/speech/analyzerinputconverter)) The current `SpeechAnalyzer` sample code uses `AnalyzerInputConverter`, which is iOS 27 only. **Since Butter's minimum is iOS 26, write the iOS 26 buffer path, or gate the helpers behind `if #available(iOS 27, *)`.** Apple's updates page lists no change to device support or module behaviour.
- **AVAudioSession in iOS 27:** adds lifecycle notifications (`didBecomeActiveNotification`, `didBecomeInactiveNotification` with a `DeactivationContext`, and `resumptionRecommendationNotification`). Apple recommends them for new code because they "don't get out of sync when the system can't deliver an end event". Butter still needs `interruptionNotification` on iOS 26. ([Handling audio interruptions](https://developer.apple.com/documentation/avfaudio/handling-audio-interruptions))

---

## 2. Not hearing its own speech

Options:

1. **Half-duplex (recommended baseline).** While `AVSpeechSynthesizer` speaks, stop yielding microphone buffers to the analyzer (or remove the input tap). Resume on `speechSynthesizer(_:didFinish:)` or `didCancel`. Leave a short guard of about 200–300 ms so the speaker tail isn't transcribed. `SpeechAnalyzer` explicitly supports gaps: "To skip past part of an audio stream, omit the buffers you want to skip from the input sequence. You can resume with a later buffer." ([SpeechAnalyzer](https://developer.apple.com/documentation/speech/speechanalyzer)) The cost is that the user can't say "stop" in the middle of a Step. Offer a large on-screen tap target, and keep Steps short.
2. **Voice processing (echo cancellation).** `AVAudioInputNode.setVoiceProcessingEnabled(true)` enables the voice-processing I/O unit, with "echo cancellation, noise suppression, automatic gain control" ([WWDC23 session 10235](https://developer.apple.com/videos/play/wwdc2023/10235/), [setVoiceProcessingEnabled](https://developer.apple.com/documentation/avfaudio/avaudioionode/setvoiceprocessingenabled(_:))). **Pitfall:** with voice processing on, the system ducks "other audio", which WWDC23 defines as "all the audio streams other than the voice audio stream from your app", including other apps. "In the past, we applied a fixed amount of ducking to other audio." iOS 17 added `voiceProcessingOtherAudioDuckingConfiguration` (advanced ducking, and a `duckingLevel` of min, mid or max) to tune it ([docs](https://developer.apple.com/documentation/avfaudio/avaudioinputnode/voiceprocessingotheraudioduckingconfiguration-swift.property)). Even at `.min`, music would be lowered for the *whole* session, not just while Butter speaks. Voice processing also implies the `voiceChat` mode with its own equalisation and routes ([voiceChat](https://developer.apple.com/documentation/avfaudio/avaudiosession/mode-swift.struct/voicechat)). The sources don't say whether it cancels *other apps'* music from the microphone signal. **(unverified)** Use it only as an experiment if half-duplex proves insufficient.
3. **Text filtering:** ignore any recognized text that matches the Step currently being spoken. This is cheap extra protection if the half-duplex guard leaks **(inference)**.

**Music bleeding into the microphone:** with music playing from the same phone's speaker and no echo cancellation, the transcriber will hear lyrics. The narrow command vocabulary and whole-token matching are the main defence. Measure false triggers on a device with a vocal track playing. **(needs device test)**

---

## 3. Audio session: listen while music plays, lower it only while speaking

Facts:

- `playAndRecord` is "nonmixable" by default. "Activating your session will interrupt any other audio sessions which are also nonmixable. To allow mixing for this category, use the mixWithOthers option." ([playAndRecord](https://developer.apple.com/documentation/avfaudio/avaudiosession/category-swift.struct/playandrecord))
- With `.mixWithOthers`, "your app mixes its audio with audio playing in background apps, such as the Music app" ([mixWithOthers](https://developer.apple.com/documentation/avfaudio/avaudiosession/categoryoptions-swift.struct/mixwithothers)).
- `.duckOthers` "reduces the volume of other audio sessions while audio from this session plays" and implies `.mixWithOthers`. "**Ducking begins when you activate your app's audio session and ends when you deactivate the session.**" "Set this option on a temporary basis only. Don't use it to duck the audio of other apps for more than a few seconds." For occasional speech like navigation, "you should also set the interruptSpokenAudioAndMixWithOthers option." ([duckOthers](https://developer.apple.com/documentation/avfaudio/avaudiosession/categoryoptions-swift.struct/duckothers))
- `.interruptSpokenAudioAndMixWithOthers` *pauses* other apps using the `spokenAudio` mode (podcasts, audiobooks) while Butter's session is active. You must then deactivate with `.notifyOthersOnDeactivation` so they can resume ([docs](https://developer.apple.com/documentation/avfaudio/avaudiosession/categoryoptions-swift.struct/interruptspokenaudioandmixwithothers), [notifyOthersOnDeactivation](https://developer.apple.com/documentation/avfaudio/avaudiosession/setactiveoptions/notifyothersondeactivation)).
- `playAndRecord` routes to the receiver (earpiece) unless you set `.defaultToSpeaker` ([defaultToSpeaker](https://developer.apple.com/documentation/avfaudio/avaudiosession/categoryoptions-swift.struct/defaulttospeaker)). `.allowBluetoothA2DP` keeps stereo Bluetooth output available in `playAndRecord` ([allowBluetoothA2DP](https://developer.apple.com/documentation/avfaudio/avaudiosession/categoryoptions-swift.struct/allowbluetootha2dp)). Note that `defaultToSpeaker` overrides headphones: "the route remains to the built-in mic and speaker" (same source). Decide whether that's acceptable, or set it only when no headphones are connected.
- "Deactivating an audio session with running audio objects stops the objects, makes the session inactive, and returns an isBusy error." ([setActive(_:options:)](https://developer.apple.com/documentation/avfaudio/avaudiosession/setactive(_:options:)))
- `AVSpeechSynthesizer.usesApplicationAudioSession = false` makes "the system create a separate audio session to automatically manage speech, interruptions, and mixing and ducking the speech with other audio sources" ([docs](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer/usesapplicationaudiosession)). WWDC20 describes that as ducking against *your own* app's audio ([WWDC20 session 10022](https://developer.apple.com/videos/play/wwdc2020/10022/)). Whether it ducks other apps' music isn't documented **(unverified)**. Don't rely on it. Keep the default (`true`) and manage the session yourself.

**Recommended sequence (inference built on the facts above):**

```
Listening (most of the session):
  category .playAndRecord, mode .default,
  options [.mixWithOthers, .defaultToSpeaker, .allowBluetoothA2DP]
  setActive(true); engine running; mic buffers -> analyzer

Read a Step:
  1. stop feeding mic (half-duplex); stop the AVAudioEngine
  2. setActive(false, .notifyOthersOnDeactivation)   // avoids isBusy
  3. setCategory(.playAndRecord, options: [.duckOthers,
       .interruptSpokenAudioAndMixWithOthers, .defaultToSpeaker, .allowBluetoothA2DP])
  4. setActive(true)              // ducking starts here
  5. synthesizer.speak(step)
  6. didFinish -> setActive(false, .notifyOthersOnDeactivation)  // ducking ends, music ramps back
  7. restore the listening options, setActive(true), restart engine, resume feeding
```

Steps 2–4 and 6–7 make the system ramp the music down and up on every Step, and add some latency. Session calls block, so make them off the main thread. Keep each utterance short, because of Apple's "more than a few seconds" warning.

**Apple Music and Spotify:** with `.mixWithOthers` they keep playing, and with `.duckOthers` the *system* lowers their volume. Neither app has to cooperate, and Butter never touches their playback. Audio that a nonmixable session interrupts, or that `interruptSpokenAudioAndMixWithOthers` pauses, is the case where the other app receives an interruption and may or may not resume. Butter avoids that case for music by always mixing. Neither Spotify nor Apple publishes how Spotify handles it, so confirm on a device that Spotify isn't paused when Butter activates `playAndRecord`. **(needs device test)** If Butter ever activates without `.mixWithOthers`, for example because of a bug in the reconfigure step, music stops and may not come back. That's the biggest regression to guard against.

---

## 4. AVSpeechSynthesizer voice quality

- `AVSpeechSynthesisVoiceQuality` has `.default`, `.enhanced` and `.premium`. Premium is "a premium quality voice that you must download to use" (iOS 16+) ([premium](https://developer.apple.com/documentation/avfaudio/avspeechsynthesisvoicequality/premium)).
- `AVSpeechSynthesisVoice.speechVoices()` lists the voices installed on the device. "This list will be updated as new voices are downloaded in Accessibility Settings." "Although Siri voices are available to be selected in Spoken Content Settings, they are not available through the AVSpeechSynthesizer API." ([speechVoices](https://developer.apple.com/documentation/avfaudio/avspeechsynthesisvoice/speechvoices()), [WWDC20-10022](https://developer.apple.com/videos/play/wwdc2020/10022/))
- `prefersAssistiveTechnologySettings` on an utterance applies the voice, rate and pitch of a running assistive technology (WWDC20-10022). It's a good accessibility default.
- You must keep the synthesizer object alive: "The system doesn't automatically retain the speech synthesizer" ([AVSpeechSynthesizer](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer)).
- Recommendation: choose the highest-quality installed voice for `Locale.current`. Optionally tell the user once that a better voice can be downloaded in Settings. Butter can't download voices itself. Voice quality is the same on the iPhone 15 and the 15 Pro, because these are system voices and not Apple Intelligence voices **(inference)**.

---

## 5. Screen awake, battery and locking

- `UIApplication.isIdleTimerDisabled`: "set this property only if necessary and … reset it to false when the need no longer exists". Disabling it is meant for apps that "need to continue displaying content when user interaction is minimal". ([isIdleTimerDisabled](https://developer.apple.com/documentation/uikit/uiapplication/isidletimerdisabled)) A Cooking session fits that. Set it on session start, clear it on stop or when the app goes to the background.
- When the screen locks or the app goes to the background without the `audio` background mode, "the system deactivates an app's audio session when it suspends the app process". On resume, the app gets a delayed interruption notification with `AVAudioSessionInterruptionWasSuspendedKey = true`. ([interruptionNotification](https://developer.apple.com/documentation/avfaudio/avaudiosession/interruptionnotification)) Butter should pause listening on `scenePhase != .active` and resume, re-activating the session, on return.
- `playAndRecord` continues "with the screen locked" only if `UIBackgroundModes` includes `audio` ([playAndRecord](https://developer.apple.com/documentation/avfaudio/avaudiosession/category-swift.struct/playandrecord)). App Review Guideline 2.5.4: "Multitasking apps may only use background services for their intended purposes: VoIP, audio playback, location, task completion, local notifications, etc." 2.5.14 requires "a clear visual and/or audible indication when recording". ([App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)) Background microphone listening for voice commands is a review risk, and the map already scopes it to the foreground. **Don't add the background audio mode in v1.**
- Battery: guideline 2.4.2 says apps "should not rapidly drain battery". The levers are `SpeechDetector` gating, a dimmed but awake screen (your choice), and stopping the engine whenever the session isn't on screen. Apple publishes no battery figures. Measure a 30–60 minute session on the iPhone 15 **(needs device test)**.

---

## 6. Interaction with Siri intents during a session

- From iOS 26, App Intents declare `supportedModes` (`.background`, `.foreground(.immediate | .dynamic | .deferred)`), and `perform()` can read `systemContext.currentMode` ([supportedModes](https://developer.apple.com/documentation/appintents/appintent/supportedmodes), [IntentModes](https://developer.apple.com/documentation/appintents/intentmodes)). Next, back, repeat and stop intents should run in the app process and act on the *same* Cooking session model as the on-device listener. Then "Hey Siri, next step in Butter" and a spoken "next" do exactly the same thing **(inference)**.
- Invoking Siri takes the microphone and audio route, so Butter's session gets a system interruption. Handle `interruptionNotification` on iOS 26, or `didBecomeInactiveNotification` / `resumptionRecommendationNotification` on iOS 27 ([Handling audio interruptions](https://developer.apple.com/documentation/avfaudio/handling-audio-interruptions)), then re-activate and restart the engine. Don't double-apply a command: if a Siri intent just ran "next", drop any local transcript received during the interruption. The documentation doesn't cover how a Siri interruption is reported to the app (reason codes). **(needs device test)**
- Phone calls: activating `playAndRecord` "when another app is already hosting a call" fails with `AVAudioSessionErrorInsufficientPriority` ([setActive](https://developer.apple.com/documentation/avfaudio/avaudiosession/setactive(_:options:))). Show listening as paused, and keep the on-screen controls working.
- `AudioRecordingIntent` (iOS 18) requires a Live Activity for as long as recording continues ([docs](https://developer.apple.com/documentation/appintents/audiorecordingintent)). It's not needed for a foreground-only session, and is noted here only so nobody reaches for it.

---

## Recommendations for decision #10

1. **Listening engine:** `SpeechAnalyzer` + `DictationTranscriber` (contextual strings for the commands, `.farField`) + `SpeechDetector(.medium)`. Upgrade to `SpeechTranscriber` where `isAvailable` is true *only if* device tests show better command accuracy. Hide hands-free listening cleanly if neither module supports the locale, or if microphone permission is denied (progressive enhancement). Siri and the on-screen buttons still work.
2. **Self-hearing:** half-duplex, muting the mic feed while speaking with a short tail guard. No voice processing in v1.
3. **Audio session:** `playAndRecord` + `mixWithOthers` + `defaultToSpeaker` + `allowBluetoothA2DP` while listening. Reactivate with `duckOthers` + `interruptSpokenAudioAndMixWithOthers` for each spoken Step, and deactivate with `notifyOthersOnDeactivation`.
4. **Voice:** `AVSpeechSynthesizer`, best installed voice (premium, then enhanced, then default), `prefersAssistiveTechnologySettings = true`.
5. **Lifecycle:** disable the idle timer only during a session. Pause on background or lock, resume on foreground. No background audio mode.
6. **Siri:** shared Cooking session state behind App Intents. Resume listening after the interruption.
7. **iOS floor:** write the iOS 26 `AVAudioEngine` buffer path. iOS 27's `CaptureInputSequenceProvider` and `AnalyzerInputConverter` and the new session lifecycle notifications are optional `#available` improvements.

### Open questions that need a real iPhone (not the Simulator)

- `SpeechTranscriber.isAvailable` on the iPhone 15. Compare its command accuracy with `DictationTranscriber`'s, with music playing.
- False triggers from song lyrics with music on the phone's own speaker.
- That Spotify keeps playing, and ducks and recovers, across repeated reactivation; and the latency of the reactivation sequence.
- Battery drain over a 30–60 minute session.
- What Butter receives when Siri is invoked mid-session, and how long recovery takes.

# Siri and App Intents for Butter on iOS 26 and iOS 27

Research for [#5](https://github.com/joshaustintech/Butter/issues/5). Researched 2026-11-21, against Apple documentation as published then and WWDC26 sessions. The current shipping release is iOS 27.2. iOS 27.3 is in developer beta.

Target devices: **iPhone 15 Pro** (Apple Intelligence) and **iPhone 15** (no Apple Intelligence).

## The short version

There are three Siri "tiers", and Butter's features fall into them very differently:

1. **Classic App Intents + App Shortcuts** (iOS 16+, every device, no Apple Intelligence). Fixed phrases that must contain "Butter". They can take parameters from a known list, speak a dialog, and ask follow-up questions. **This is the only tier that reaches the iPhone 15, and the only one that reaches an external TestFlight tester today.**
2. **Apple Intelligence system features with a schema or a fixed role** (Apple Intelligence devices). Visual intelligence search (iOS 26+), the Spotlight semantic index, and App Schemas in *primary domains*. **No domain fits recipes.** Only `.system.searchInApp`, `.system.open` (iOS 27) and the visual intelligence search schema are generic enough for Butter.
3. **Siri AI with custom actions and content** (`@AppIntent(.tool)`, iOS **27.3** beta, Apple Intelligence devices). This is what would make "save this to Butter", natural recipe questions, "open it" follow-ups and app-name-free cooking commands work. It is a **Developer Preview**. It works only for development builds and **internal** TestFlight testers. App Store submission opens "in the spring", and it does not reach external TestFlight testers.

Butter's v1 Siri experience has to be built on tier 1. Tier 2 adds a little. Tier 3 is a later progressive enhancement that can't be shipped to the other tester yet.

One trap to know about: **adding any tool intent makes the app's App Shortcuts unavailable to Siri.** (They stay available in Spotlight and the Action button.)

## Platform status

| Fact | Source |
|---|---|
| Apple Intelligence and Siri AI need iPhone 15 Pro / Pro Max, iPhone 16 or later, iPhone Air or iPhone Duo. The iPhone 15 is not supported. | [How to get Apple Intelligence (support.apple.com/121115)](https://support.apple.com/121115); [Apple Newsroom, June 2026](https://www.apple.com/newsroom/2026/06/apple-introduces-siri-ai-a-profoundly-more-capable-and-personal-assistant/) |
| The "personal context / onscreen awareness" Siri promised since iOS 18 did **not** ship in iOS 26. The 26.4 beta shipped without it, and the features moved to the iOS 27 cycle as "Siri AI". | [MacRumors, 2026-02-17](https://www.macrumors.com/2026/02/17/ios-26-4-no-new-siri-features/) (secondary; Apple's later announcement below confirms Siri AI arrives with 27) |
| Siri AI was announced at WWDC26 for iOS 27. It is a beta for users, requires a supported language, and is not available in the EU on iOS at first. It is also subject to daily usage limits. | [Apple Newsroom, June 2026](https://www.apple.com/newsroom/2026/06/apple-introduces-siri-ai-a-profoundly-more-capable-and-personal-assistant/); [support.apple.com/121115](https://support.apple.com/121115) |
| Third-party custom integration is a Developer Preview starting in the iOS 27.3 betas (2026-11-03). Per Apple, it gives "early access before first shipping to customers in a few months", and App Store submission opens "in the spring". | [Apple Developer News: Siri AI is now open to all developers](https://developer.apple.com/news/?id=gdk2umrf) |
| Developer Preview features run only in development-signed builds and for **internal** TestFlight testers. They are "not available to external testers in TestFlight or to versions of your app that you publish on the App Store". | [Siri AI Developer Preview](https://developer.apple.com/documentation/appintents/siri-ai-developer-preview) |
| `ToolIntent`, `AppEntity(_:)` traits (generable entities) and `CardSnippet` are iOS 27.3+. `IndexedEntityQuery` and `.system.open` are iOS 27.0+. | Symbol availability on [ToolIntent](https://developer.apple.com/documentation/appintents/toolintent), [CardSnippet](https://developer.apple.com/documentation/appintents/cardsnippet), [IndexedEntityQuery](https://developer.apple.com/documentation/appintents/indexedentityquery), [system.open](https://developer.apple.com/documentation/appintents/appschema/systemintent/open) |
| "Adding any tool intent to your app makes your App Shortcuts unavailable to Siri ... App Shortcuts remain available to other system experiences like Spotlight or the Action button." | [Bringing custom actions and content to Siri](https://developer.apple.com/documentation/appintents/bringing-custom-actions-and-content-to-siri) |

## App schema domains: none fit a recipe app

Apple's primary (Siri-enabled) domains are Audio, Calendar, Camera, Clock, Mail, Maps, Messages, Notes, Phone, Photos, Reminders, System and in-app search, and Video. Visual intelligence and Assistant are single-purpose domains. Books, **Browser**, **Files**, Journaling, Presentation, **Reader**, Spreadsheet, Whiteboard and Word processor are "Shortcuts-specific" domains: they "work with the Shortcuts app but don't make your conforming types discoverable by Apple Intelligence and Siri" ([App schema domains](https://developer.apple.com/documentation/appintents/app-schema-domains)).

There is no recipe or food domain. Apple says to "only apply schemas for actions and content that genuinely match the domain's intended purpose" ([Making actions and content discoverable](https://developer.apple.com/documentation/appintents/making-actions-and-content-discoverable-by-apple-intelligence)). So Butter shouldn't pretend a Recipe is a `.notes` note or a `.photos` asset. The generic schemas that do apply:

- `.system.searchInApp` opens Butter's own search UI with the spoken term ("Show me chicken recipes in Butter"). It works "no matter which other domains you adopt, and even if you don't index your entities" ([WWDC26 session 343](https://developer.apple.com/videos/play/wwdc2026/343/); [System and in-app search](https://developer.apple.com/documentation/appintents/app-schema-domain-system-and-in-app-search)). It navigates; it doesn't give a spoken answer.
- `.system.open` (iOS 27) opens an entity ("Open my lemon chicken").
- `.visualIntelligence.semanticContentSearch` (iOS 26) is the "More results" button in visual intelligence (see below).

## Feature by feature

### 1. "Save this to Butter" for an onscreen photo or Safari page

**iOS 26, any device: not possible through Siri.** Siri on iOS 26 has no onscreen awareness. The onscreen APIs (`NSUserActivity.appEntityIdentifier`, view annotations) exist since iOS 18.2 ([Providing contextual cues](https://developer.apple.com/documentation/appintents/providing-contextual-cues-to-apple-intelligence-and-siri)), but the Siri that consumes them didn't ship (see Platform status). Even where they work, these APIs let the app that *shows* the content (Photos, Safari) describe it. Butter would be the receiving app.

**Visual intelligence (iOS 26+, Apple Intelligence only)** is not a save path. The system sends Butter a `SemanticContentDescriptor` (English labels plus a `pixelBuffer`) through an `IntentValueQuery`, and Butter returns *matching existing entities* as search results. A `semanticContentSearch` intent can open Butter's full results ([Integrating your app with visual intelligence](https://developer.apple.com/documentation/visualintelligence/integrating-your-app-with-visual-intelligence); [Visual intelligence domain](https://developer.apple.com/documentation/appintents/app-schema-domain-visual-intelligence)). You could technically take the pixel buffer from "More results" and import it, but that misuses a search API. I don't recommend it.

**iOS 27.3+ with Siri AI (Developer Preview, Apple Intelligence only): possible, internal testers only.** Siri AI "can find custom content from one app, transfer it to another app, and perform an action". Apple's own Photos and Safari gain Siri AI capabilities in 27.3 ([Siri AI Developer Preview](https://developer.apple.com/documentation/appintents/siri-ai-developer-preview); [Developer News](https://developer.apple.com/news/?id=gdk2umrf)). Butter would add an `@AppIntent(.tool)` "Save to Butter" intent whose parameter takes a transferable image/file or URL. Transfer between apps relies on `Transferable` representations ([Bringing custom actions and content to Siri](https://developer.apple.com/documentation/appintents/bringing-custom-actions-and-content-to-siri)). The one developer report of the image hand-off working on iOS 27 used a `.files.file` entity with `FileEntityIdentifier` and a `FileRepresentation`, and in-memory images were not picked up ([forum thread 838329](https://developer.apple.com/forums/thread/838329), developer reports, not Apple). **Needs a device spike.**

**Fallback that works everywhere:** the Share Extension from Safari and Photos, already in the map's "ways in".

### 2. App Shortcut phrases with the app name ("Add to Butter")

**iOS 16+, every device, no Apple Intelligence needed, zero user setup.** "All trigger phrases must contain your app name or an app name synonym" (`\(.applicationName)` token). App Shortcuts "are automatically available as soon as your app is installed and require zero user setup" ([WWDC23 session 10102](https://developer.apple.com/videos/play/wwdc2023/10102/); [App Shortcuts](https://developer.apple.com/documentation/appintents/app-shortcuts)).

What "Add to Butter" can actually *do* without onscreen awareness: it can't see what's on screen. It can open the camera import or start a manual entry, or (because the share sheet holds the real content) it can be a phrase-less Shortcuts action. So "add to Butter" is really "open Butter's camera" unless Siri AI is present.

Caveat: once Butter ships any tool intent, App Shortcuts stop being available to Siri (see Platform status).

### 3. Spoken answers ("recipes I saved last week", "recipes with chicken")

**Classic (iOS 16+, every device).**
- An intent returning `ProvidesDialog` speaks an `IntentDialog` ([ProvidesDialog](https://developer.apple.com/documentation/appintents/providesdialog)). `IntentDialog(full:supporting:)`'s full string "must stand alone for voice-only devices" ([WWDC26 session 343](https://developer.apple.com/videos/play/wwdc2026/343/)). Listing up to 5 titles in the dialog works.
- Phrase parameters must have "a fixed set of well-known parameter values". Use `AppEnum` cases or `AppEntity` values from `suggestedEntities`, refreshed with `updateAppShortcutParameters()`. App Shortcuts "do not support open-ended values like 'Search my app for X'" ([WWDC23 session 10102](https://developer.apple.com/videos/play/wwdc2023/10102/)).
  - **Dates:** model "last week" as an `AppEnum` time window (today, yesterday, this week, last week, this month), e.g. "Recipes I saved last week in Butter". Free-form dates are not phrase parameters.
  - **Ingredients:** an `IngredientEntity` whose suggested values are the distinct ingredient names in the library makes "Butter recipes with chicken" matchable, because entity values are dynamic. If a name isn't recognized, a required `String` parameter makes Siri ask "Which ingredient?" ("App Shortcuts automatically prompts for a value ... if the parameter is not optional", same session). How well large dynamic value lists match needs testing on a device.
- `EntityStringQuery` lets Butter search title and Ingredients itself when Siri hands it a string ([WWDC26 session 240](https://developer.apple.com/videos/play/wwdc2026/240/)).

**Spotlight indexing (iOS 18+, every device).** `IndexedEntity` with `indexingKey` properties, indexed with `CSSearchableIndex.indexAppEntities`, makes Recipes findable in Spotlight on any device ([IndexedEntity](https://developer.apple.com/documentation/appintents/indexedentity); [Making app entities available in Spotlight](https://developer.apple.com/documentation/appintents/making-app-entities-available-in-spotlight)). iOS 27 adds `IndexedEntityQuery` for reindexing.

**Siri AI (Apple Intelligence; custom content is iOS 27.3 Developer Preview).** "Siri AI can now surface any entity in the Spotlight semantic index, not just the ones that fit an existing schema" ([Developer News](https://developer.apple.com/news/?id=gdk2umrf)). With `IndexedEntity` plus property descriptions, Siri could answer "what did I save last week?" from the index, matching "based on meaning, not just text" ([WWDC26 session 240](https://developer.apple.com/videos/play/wwdc2026/240/)). Note: under Siri AI "the system might not display the IntentDialog you return" ([IntentDialog](https://developer.apple.com/documentation/appintents/intentdialog)), so the spoken wording isn't Butter's to control there.

### 4. Follow-ups such as "open it"

**Classic (every device): no conversational memory.** After an App Shortcut finishes, "open it" is a new request with no context. Workarounds inside one intent run:
- Ask before finishing: `requestConfirmation` ("Want me to open Lemon Chicken?"), or `$param.requestDisambiguation(among:dialog:)` to pick one of several (iOS 16+).
- Return `OpensIntent` (`.result(value:opensIntent:)`) to chain an open intent ([OpensIntent](https://developer.apple.com/documentation/appintents/opensintent)).
- Use `supportedModes` with `.foreground(.dynamic)` to continue into the app (iOS 26+, [supportedModes](https://developer.apple.com/documentation/appintents/appintent/supportedmodes)).
- Use an interactive `SnippetIntent` (iOS 26+) with tappable rows ([SnippetIntent](https://developer.apple.com/documentation/appintents/snippetintent)), though that is not voice.

**Siri AI:** follow-ups are native. People "can extend almost any response from Siri into a rich conversation and ask follow-up questions" ([Newsroom](https://www.apple.com/newsroom/2026/06/apple-introduces-siri-ai-a-profoundly-more-capable-and-personal-assistant/)). The app doesn't need to be named "when a person continues a conversation in the Siri app that includes a mention of your app" ([Siri AI Developer Preview](https://developer.apple.com/documentation/appintents/siri-ai-developer-preview)). "Open it" then resolves to an `OpenIntent` / `.system.open`. Custom content: 27.3 preview only.

### 5. Cooking session by voice (open Recipe, next, previous, repeat), including the lock screen

**Classic (every device).** Intents for Next / Previous / Repeat / Stop Step, with App Shortcut phrases such as "Next step in Butter". Every command needs "Butter" in it. `authenticationPolicy` defaults to `.alwaysAllowed`, "which allows the intent to run without authentication, including when the device is locked" ([authenticationPolicy](https://developer.apple.com/documentation/appintents/appintent/authenticationpolicy)). So Step commands that run in the background (`supportedModes = .background`) work from the lock screen. An intent that must bring the app to the foreground (opening a Recipe on screen) needs an unlock. A Live Activity for the session can carry `LiveActivityIntent` buttons (iOS 17+, [LiveActivityIntent](https://developer.apple.com/documentation/appintents/liveactivityintent)) for touch control on the lock screen. Butter's own in-session listening (the map's next / back / repeat / stop) is the app-name-free path and doesn't depend on Siri at all.

**Siri AI (27.3 preview).** People "don't have to mention your app in their request while your app is in the foreground, while a Live Activity is active" ([Siri AI Developer Preview](https://developer.apple.com/documentation/appintents/siri-ai-developer-preview)). With tool intents and a Cooking session Live Activity, "Siri, next step" would work without "Butter", but only for internal testers until spring.

## Feature against requirement

| Feature | iOS 26, iPhone 15 (no AI) | iOS 26, iPhone 15 Pro (AI) | iOS 27.0–27.2, iPhone 15 Pro (AI) | iOS 27.3+ Siri AI preview (AI, dev/internal builds only) |
|---|---|---|---|---|
| "Save this to Butter" (onscreen photo / Safari page) | No. Share sheet only | No. Share sheet only | No. Share sheet only (no third-party custom actions yet) | Yes, via a tool intent taking a transferable file/URL (spike needed) |
| Visual intelligence | No | Search existing Recipes only (`IntentValueQuery` + `SemanticContentDescriptor`) | Same | Same |
| App Shortcut phrases with "Butter" | Yes | Yes | Yes | **Turned off in Siri if any tool intent exists** (still in Spotlight / Action button) |
| Spoken answer to fixed-shape queries (enum date window, ingredient entity) | Yes | Yes | Yes | Yes (Siri may replace Butter's dialog) |
| Free-form natural questions over Recipes | No | No | Only if a schema fits (none does) | Yes, via Spotlight semantic index + `IndexedEntity` |
| Spotlight search of Recipes | Yes (`IndexedEntity`, iOS 18+) | Yes | Yes, plus `IndexedEntityQuery` reindexing | Yes |
| In-app search by voice ("chicken recipes in Butter") | App Shortcut + enum/entity param | Same | `.system.searchInApp` also | Same |
| "Open it" follow-up | Only as a confirmation inside the same intent | Same | Same | Yes, native follow-ups |
| Cooking commands by Siri | Yes, must say "Butter"; lock screen OK for background intents | Same | Same | Yes, without "Butter" while the Live Activity is up |
| Butter's own on-device listening during a session | Yes (not Siri; Speech framework) | Yes | Yes | Yes |

## Recommendations

**For [#9](https://github.com/joshaustintech/Butter/issues/9) (features per device):**
- Treat Siri AI custom integration as **not available in v1** on any device. It needs iOS 27.3 plus Siri AI, and it is blocked for external TestFlight testers and the App Store until App Store submission opens in spring 2027. The only gap between iPhone 15 Pro and iPhone 15 in v1 is visual intelligence search (and the on-device model for imports, out of scope here).
- "Save this to Butter" by voice is **hidden on both devices in v1**. The Share button is the universal path, and onboarding should teach it. Revisit when App Store submission for Siri AI opens.
- Spoken queries, "open it" (as a confirmation question) and cooking commands are **full on both devices** through App Shortcuts. Their wording is fixed and includes "Butter".
- Visual intelligence search (Apple Intelligence only) is an optional, invisible-when-absent extra. It's low priority.
- Keep tool intents out of shipped builds (compile them only in an internal configuration) until they ship to customers, because their presence disables App Shortcuts in Siri.

**For [#10](https://github.com/joshaustintech/Butter/issues/10) (Cooking session):**
- Siri commands: "Start cooking <Recipe> in Butter", "Next step in Butter", "Previous step in Butter", "Repeat step in Butter", "Stop cooking in Butter". Run Step commands with `supportedModes = .background` and `.alwaysAllowed` so they work when the phone is locked. Opening a Recipe needs the phone unlocked.
- Put a Live Activity on the lock screen with Next / Back / Repeat buttons (`LiveActivityIntent`). Later, the same Live Activity is what lets Siri AI drop the app name.
- Butter's own in-session listening is the app-name-free path on every device, so the Siri commands are for starting the session and as a backup.
- Mark the Step intents `AudioPlaybackIntent` if Butter speaks the Step, so "the system can then avoid dialogue or other experiences that might interrupt that audio" ([AudioPlaybackIntent](https://developer.apple.com/documentation/appintents/audioplaybackintent)). Check how this interacts with ducking other apps' music.

## Open questions (need a real device)

- Does Siri on iOS 27.3 actually hand a Safari page (URL) or a Photos image to a third-party tool intent? Only the reverse direction (an app's own content) has a developer report.
- Does adding a tool intent also disable App Shortcuts in Siri on a device *without* Apple Intelligence? The docs don't distinguish.
- How well do App Shortcut entity parameters match a large, dynamic ingredient list?
- Siri can't be tested on the installed simulator in any meaningful way. All of the above needs the iPhone 15 Pro and iPhone 15.

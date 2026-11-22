# On-device recipe extraction (photos and webpages), iOS 26+

Research for [#3](https://github.com/joshaustintech/Butter/issues/3), part of map [#2](https://github.com/joshaustintech/Butter/issues/2).
Question: on iOS 26+, with no server, how can Butter turn (a) a photo of a cookbook page and (b) a recipe webpage into a structured Recipe (title, Ingredients, ordered Steps)?

Researched 2026-11-21. Sources are Apple developer documentation (fetched as Markdown from `developer.apple.com/tutorials/data/documentation/...`), WWDC sessions, apple.com, schema.org, Google Search Central, and direct fetches of live recipe pages.

## Answer in brief

| Path | Every iPhone on iOS 26 (incl. iPhone 15) | Apple Intelligence (iPhone 15 Pro) |
|---|---|---|
| Webpage | Share extension runs a JS preprocessing file in Safari, pulls `application/ld+json` blocks, and maps schema.org `Recipe` (`name`, `recipeIngredient`, `recipeInstructions`) to a Recipe. No AI needed. | Same JSON-LD path first. The model is only a fallback for pages without Recipe data (visible page text into a `@Generable` Recipe). |
| Photo | Vision `RecognizeDocumentsRequest` (iOS 26) gives paragraphs, lines and lists; simple rules split them into Ingredients and Steps. | Same OCR, then the on-device model turns the OCR text into a `@Generable` Recipe. On iOS 27 the image can also be attached to the prompt directly. |

Everything here runs on the device. The only thing that differs between the two target phones is whether `SystemLanguageModel.default.availability` is `.available`.

## 1. Photos: Vision text recognition

- **Works on every iPhone.** Vision's text APIs are not tied to Apple Intelligence. `VNRecognizeTextRequest` has existed since iOS 13 ([docs](https://developer.apple.com/documentation/vision/vnrecognizetextrequest)), the Swift `RecognizeTextRequest` since iOS 18 ([docs](https://developer.apple.com/documentation/vision/recognizetextrequest)), and `RecognizeDocumentsRequest` since iOS 26 ([docs](https://developer.apple.com/documentation/vision/recognizedocumentsrequest)). WWDC25 says "all vision APIs run entirely on-device" ([WWDC25 272, Read documents using the Vision framework](https://developer.apple.com/videos/play/wwdc2025/272/)).
- **`RecognizeDocumentsRequest` is the right API for a cookbook page.** Apple describes it as being for "structured texts like receipts, nutritional labels, textbook pages, forms" ([docs](https://developer.apple.com/documentation/vision/recognizedocumentsrequest)). It returns a `DocumentObservation` whose container holds text, **lists**, tables and barcodes. Text is available as a transcript, lines, **paragraphs** and words ([DocumentObservation](https://developer.apple.com/documentation/vision/documentobservation); WWDC25 272). It recognises 26 languages (WWDC25 272). A bulleted or numbered ingredient list should come back as a list container, and method paragraphs as paragraphs. That is the most useful signal for the rules in section 4.
- **Accuracy:** Apple publishes no accuracy figures. `RecognizeTextRequest` offers `.accurate` and `.fast` recognition levels plus language correction and `customWords` ([recognitionLevel](https://developer.apple.com/documentation/vision/recognizetextrequest/recognitionlevel-swift.property), [VNRecognizeTextRequest](https://developer.apple.com/documentation/vision/vnrecognizetextrequest)). Use `.accurate` for imports. Fractions (½, ¼), unit abbreviations and two-column layouts are the likely weak spots. This needs a hands-on check with real cookbook photos (see Open questions).

## 2. Webpages: schema.org Recipe JSON-LD in a share extension

- **Mechanism (iOS 8+, unchanged):** add `NSExtensionJavaScriptPreprocessingFile` to the share extension's `NSExtensionAttributes` and set `NSExtensionActivationSupportsWebPageWithMaxCount` to a nonzero value. Safari runs the file's `ExtensionPreprocessingJS.run(arguments)` in the page and passes back whatever goes to `arguments.completionFunction({...})`. The extension reads it as a property list under `NSExtensionJavaScriptPreprocessingResultsKey` ([App Extension Programming Guide, Accessing a Webpage](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html); [NSExtensionJavaScriptPreprocessingResultsKey](https://developer.apple.com/documentation/foundation/nsextensionjavascriptpreprocessingresultskey)). The script runs against the live DOM, so it sees JSON-LD that is injected client-side too. It should return the raw text of every `script[type="application/ld+json"]`, plus `document.title`, the URL and `document.body.innerText` (trimmed) for the fallback. Parse in Swift.
- **Shape to parse** ([schema.org/Recipe](https://schema.org/Recipe)):
  - `name`: Text → Recipe title.
  - `recipeIngredient`: Text (usually an array of strings). It supersedes the older `ingredients`, so read both.
  - `recipeInstructions`: Text, an `ItemList`, or `CreativeWork`, in practice an array of `HowToStep` (`text`) and/or `HowToSection` (`name` + `itemListElement` of HowToSteps). Flatten sections into ordered Steps. Also handle a single string (split it on newlines or sentences).
  - `image`: URL or ImageObject (an optional Recipe photo).
  - `@type` may be `"Recipe"` or an array containing `"Recipe"`, and the node may sit inside an `@graph` array (Yoast or WP Recipe Maker sites). Search recursively.
- **How common it is:** Google lists recipe structured data as the way to get recipe rich results and carousels in Search, with `recipeIngredient` and `recipeInstructions` (HowToStep/HowToSection) as recommended properties ([Google Search Central, Recipe structured data](https://developers.google.com/search/docs/appearance/structured-data/recipe)). That gives publishers a strong incentive to include it. JSON-LD appears on 41% of all web pages ([Web Almanac 2024, Structured Data](https://almanac.httparchive.org/en/2024/structured-data)). That figure covers the whole web; the Almanac gives no Recipe-specific number.
- **Spot check (2026-11-21, `curl` with an iPhone Safari UA):** of the pages that returned a real recipe, 4 of 5 served a schema.org `Recipe` in JSON-LD in their initial HTML: NYT Cooking, Bon Appétit, King Arthur Baking (HowToStep lists) and RecipeTin Eats (HowToSection + HowToStep, inside `@graph`). BBC Good Food served no Recipe JSON-LD in its initial HTML (it may be injected client-side, which the share extension would still see). Allrecipes, Serious Eats, Simply Recipes, Budget Bytes and Food Network served bot-challenge or stub pages to `curl`, so they tell us nothing. Safari in a share extension sees the page the user sees, so those blocks don't apply. This is a small sample, not a measurement.

## 3. Foundation Models (on-device Apple Intelligence model)

### Device support and runtime check
- **iPhone 15 Pro / Pro Max: supported. iPhone 15 / 15 Plus: not supported** ([apple.com/apple-intelligence](https://www.apple.com/apple-intelligence/), which lists the iPhone 15 Pro (A17 Pro) as the oldest compatible iPhone).
- Framework available from iOS 26.0 ([Foundation Models](https://developer.apple.com/documentation/foundationmodels)). Check at runtime with `SystemLanguageModel.default.availability` ([Availability](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum)): `.available`, or `.unavailable(reason)` where `reason` is one of ([UnavailableReason](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailablereason)):
  - `.deviceNotEligible`: iPhone 15. Hide AI features for good.
  - `.appleIntelligenceNotEnabled`: capable phone, switched off. Treat it like no AI, perhaps with a gentle hint.
  - `.modelNotReady`: downloading or other system reasons. Fall back for now and try again later.
  - `isAvailable: Bool` is a shortcut ([SystemLanguageModel](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel)). Region and device language also gate availability (same page). Use `supportsLocale(_:)` as well.

### Guided generation into a Swift type
- Mark a struct `@Generable` and optionally add `@Guide(description:)` and constraints, then call `session.respond(to:generating:)`. The framework uses **constrained sampling**, which "prevents the model from producing malformed output". Properties are generated in declaration order, and nesting is supported ([Generating Swift data structures with guided generation](https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation)). A shape for Butter would be `@Generable struct RecipeDraft { var title: String; var ingredients: [String]; var steps: [String] }`. Keep it small: the schema and every `@Guide` description cost tokens ([TN3193](https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window)).
- The output is structurally valid but not guaranteed faithful. The model could still drop or paraphrase a line, so the prompt should say "copy lines verbatim".

### Context window
- **iOS 26:** 4,096 tokens per `LanguageModelSession`, shared by instructions, prompt, schema and output. A token is about 3–4 English characters. Overflowing it throws `LanguageModelSession.GenerationError.exceededContextWindowSize` ([TN3193](https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window)).
- **iOS 26.4+:** `contextSize` (back-deployed) and `tokenCount(for:)` let the app measure before sending ([contextSize](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/contextsize), [tokenCount(for:)](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/tokencount(for:))).
- **iOS 27:** the WWDC26 session's sample prints `model.contextSize // 8192` for the new on-device model ([WWDC26 241, What's new in the Foundation Models framework](https://developer.apple.com/videos/play/wwdc2026/241/)). Apple's reference docs give no fixed number, and some WWDC26 lab answers repeated 4,096, so **read `contextSize` at runtime and don't hard-code either number.**
- **What this means for Butter:** a cookbook page of OCR text, at roughly 300–600 words, fits comfortably within 4K together with the output. A full webpage's `innerText` often won't. Hence: JSON-LD first, and for the fallback send only trimmed main text. If it is still too long, split it across sessions, as TN3193 recommends (for example, find the ingredient block in one session and the method in another).

### Speed
- Apple's published figures for the on-device model on **iPhone 15 Pro** are about 0.6 ms per prompt token to the first token and about 30 tokens/s generation, for a ~3B-parameter model at ~3.7 bits per weight ([Apple ML Research, Introducing Apple's On-Device and Server Foundation Models](https://machinelearning.apple.com/research/introducing-apple-foundation-models), 2024). These are older-model numbers. Apple published no new speed figures for the 26.x or 27 models (WWDC26 241 gives none).
- Rough estimate: about 1,000 prompt tokens is under a second to the first token, and about 400 output tokens (a 10-Ingredient, 8-Step Recipe) takes around 13 s. Butter should save the rule-based result **immediately** (map #2 requires immediate save) and refine it with the model afterwards, or show progress, rather than block the spoken confirmation for more than 10 seconds. Call `prewarm()` when the import UI appears ([TN3193](https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window) uses it).

### Model versions
- There are three model versions so far: iOS 26.0–26.3, 26.4 and 27.0. Apple tells developers to test and, if needed, version prompts with `#available` checks ([SystemLanguageModel](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel); [Updating prompts for new model versions](https://developer.apple.com/documentation/foundationmodels/updating-prompts-for-new-model-versions)).

## 4. Rule-based splitting when there's no AI (iPhone 15)

No Apple source covers this. These rules are derived from the shape of the data and would be the iPhone 15 path, also used as the instant first pass on the Pro:

1. **Use the structure Vision gives you.** If `RecognizeDocumentsRequest` returns list containers, the first list (or the one with the most quantity-like lines) is Ingredients. Paragraphs after it are Steps.
2. **Headings.** Case-insensitive lines matching `ingredients|you will need|for the …` start the Ingredients section. `method|directions|instructions|preparation|steps` start Steps.
3. **Ingredient line heuristics:** the line starts with a number, fraction (`½ ¼ ¾ 1/2`) or range (`2-3`), and/or contains a unit token (`g, kg, ml, l, tsp, tbsp, cup(s), oz, lb, pinch, clove(s)`). The lines are short (usually under about 8 words).
4. **Step heuristics:** leading step numbers (`1.`, `1)`, `Step 1`), imperative verbs at the start (`Preheat, Mix, Stir, Add, Bake, Whisk…`), longer sentences. Merge wrapped lines into the current Step until the next number or a blank or paragraph break.
5. **Title:** the largest or top-most line above the Ingredients that is not a page number or chapter header. Fall back to "Untitled Recipe".
6. **Fallback:** if nothing classifies, save all text as one Step with no Ingredients. That is still "saved as best it can be" per map #2, and the user edits it afterwards.

For webpages without JSON-LD on an iPhone 15, the same rules can run over `innerText`, but results will be poor. Saving title + URL + text as Steps is the honest fallback.

## 5. iOS 26 vs iOS 27

| | iOS 26.0–26.3 | iOS 26.4 | iOS 27 |
|---|---|---|---|
| On-device model | v1 | v2: better instruction following and tool calling, fewer guardrail false positives | v3: "rebuilt from the ground up", better at logic and tool calling |
| Context | 4,096 | 4,096 + `contextSize`, `tokenCount(for:)` | `contextSize` shows 8,192 in the WWDC26 sample; read it at runtime |
| Image input to the model | No | No | Yes: `Attachment(UIImage)` inside a prompt ([Attachment](https://developer.apple.com/documentation/foundationmodels/attachment), iOS 27.0+). An image is about 200 tokens per WWDC26 labs; larger images cost more tokens and latency (WWDC26 241). |
| Vision tools for the model | No | No | `OCRTool` and `BarcodeReaderTool` ([OCRTool](https://developer.apple.com/documentation/vision/ocrtool), iOS 27.0+, **not available in Simulator**) |
| Private Cloud Compute model | No | No | `PrivateCloudComputeLanguageModel`: 32K context and reasoning, needs a managed entitlement, has quotas ([docs](https://developer.apple.com/documentation/foundationmodels/privatecloudcomputelanguagemodel)). It is Apple's server, not on-device. |
| Vision documents API | `RecognizeDocumentsRequest` (all devices) | same | same (no new Vision OCR changes listed in [Vision updates](https://developer.apple.com/documentation/updates/vision)) |

Source for the version rows: [Foundation Models updates](https://developer.apple.com/documentation/updates/foundationmodels) (February 2026 = 26.4, June 2026 = 27).

**Implication:** with a minimum of iOS 26, Butter's baseline is OCR text → `@Generable` Recipe on Apple Intelligence phones. On iOS 27 the app can add `if #available(iOS 27, *)` image attachment, so the model can see layout as well as text, which may help with two-column pages. It stays an enhancement, not a requirement. PCC conflicts with "on the phone itself" and needs an entitlement, so leave it out of v1.

## Recommendation for decisions that wait on this

1. **Webpage import does not need Apple Intelligence.** Ship the JSON-LD share extension path on every phone. Use the model only as a fallback for pages without Recipe data, on Apple Intelligence phones.
2. **Photo import works on every phone** with `RecognizeDocumentsRequest` + rules. On the iPhone 15 Pro (Apple Intelligence enabled and model ready), refine with a `@Generable` Recipe from the OCR text.
3. **Feature gating is one check:** `SystemLanguageModel.default.availability == .available`. On iPhone 15 it is always `.deviceNotEligible`, so nothing AI-related is shown and the rule-based paths are the whole product.
4. **Save first, refine after.** Save the rule-based or JSON-LD Recipe immediately, then let the model rewrite Ingredients and Steps when it finishes (seconds to tens of seconds). This keeps the spoken confirmation immediate on both phones.
5. **Don't hard-code 4,096 or 8,192.** Budget with `contextSize` and `tokenCount(for:)` (26.4+) and handle `exceededContextWindowSize`.
6. **iOS 27 image attachment and `OCRTool` are later enhancements** behind `#available`. `OCRTool` is not available in Simulator, and model features in general need the real iPhone 15 Pro for testing.

## Open questions

- Real-world OCR quality on cookbook photos (fractions, two columns, glossy-page glare): needs a hands-on prototype on the iPhone 15.
- Whether Foundation Models runs within a share extension's memory limit. No Apple doc found that says it is supported or unsupported in extensions. Verify on device, or hand off to the main app via App Group if not.
- Measured latency of the 26.x/27 models on the iPhone 15 Pro for a Recipe-sized `@Generable` output (Apple has published no new numbers).

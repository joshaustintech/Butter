import Foundation
import Vision

/// Reads the text of a page from image data. A seam so the import pipeline is
/// testable without Vision.
protocol DocumentTextRecognizing: Sendable {
    func recognizeText(in imageData: Data) async throws -> String
}

/// Vision-backed recognizer using iOS 26 `RecognizeDocumentsRequest`.
struct VisionDocumentTextRecognizer: DocumentTextRecognizing {
    func recognizeText(in imageData: Data) async throws -> String {
        let observations = try await RecognizeDocumentsRequest().perform(on: imageData)
        // `document.text` is the document's text in reading order.
        return observations.map(\.document.text.transcript).joined(separator: "\n")
    }
}

/// Imports a Recipe from a photo of a page: recognize text, then parse it.
struct PhotoRecipeImporter {
    var recognizer: any DocumentTextRecognizing = VisionDocumentTextRecognizer()

    func importRecipe(from imageData: Data) async throws -> ImportedRecipe {
        let text = try await recognizer.recognizeText(in: imageData)
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RecipeImportError.noTextFound
        }
        return RecipeTextParser.parse(text: text)
    }
}

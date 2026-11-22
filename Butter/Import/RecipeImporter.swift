import Foundation
import SwiftData

/// What to import a Recipe from.
enum RecipeImportSource {
    case webpage(URL)
    case photographedPage(Data)
}

/// The result of an import.
enum RecipeImportOutcome {
    /// A new Recipe was saved.
    case saved(Recipe)
    /// The webpage is already saved; this is the existing Recipe.
    case duplicate(Recipe)
}

/// Imports a Recipe from a webpage or a photographed page in one step: read it,
/// check for a Duplicate, and save it with its Source.
@MainActor
struct RecipeImporter {
    typealias Fetch = WebpageRecipeImporter.Fetch
    typealias Sleep = @Sendable (Duration) async throws -> Void

    /// Waits between dish photo attempts; there are `retryDelays.count + 1` attempts.
    static let retryDelays: [Duration] = [.seconds(1), .seconds(2)]

    private let fetch: Fetch
    private let recognizer: any DocumentTextRecognizing
    private let sleep: Sleep

    init(
        fetch: @escaping Fetch = WebpageRecipeImporter.liveFetch,
        recognizer: any DocumentTextRecognizing = VisionDocumentTextRecognizer(),
        sleep: @escaping Sleep = { try await Task.sleep(for: $0) }
    ) {
        self.fetch = fetch
        self.recognizer = recognizer
        self.sleep = sleep
    }

    func importRecipe(_ source: RecipeImportSource, in context: ModelContext) async throws -> RecipeImportOutcome {
        switch source {
        case .webpage(let url):
            let imported = try await WebpageRecipeImporter(fetch: fetch).importRecipe(from: url)
            let pageURL = imported.sourceURL ?? url
            let recipes = try context.fetch(FetchDescriptor<Recipe>())
            if let existing = recipes.first(where: {
                $0.source?.kind == .webpage && $0.source?.url == pageURL
            }) {
                return .duplicate(existing)
            }
            let recipe = Recipe(imported)
            if let imageURL = imported.imageURL {
                recipe.photo = await downloadDishPhoto(imageURL)
            }
            return try save(recipe, in: context)

        case .photographedPage(let image):
            let imported: ImportedRecipe
            do {
                imported = try await PhotoRecipeImporter(recognizer: recognizer).importRecipe(from: image)
            } catch let error as RecipeImportError {
                throw error
            } catch {
                throw RecipeImportError.noTextFound
            }
            let recipe = Recipe(imported)
            recipe.source = Source(photographedPage: image)
            return try save(recipe, in: context)
        }
    }

    private func save(_ recipe: Recipe, in context: ModelContext) throws -> RecipeImportOutcome {
        context.insert(recipe)
        try context.save()
        return .saved(recipe)
    }

    /// Tries up to 3 times, retrying only on network errors and 5xx. Returns nil on failure.
    private func downloadDishPhoto(_ url: URL) async -> Data? {
        for attempt in 0...Self.retryDelays.count {
            do {
                let (data, response) = try await fetch(url)
                guard let http = response as? HTTPURLResponse else { return nil }
                if (200..<300).contains(http.statusCode) { return data }
                if !(500..<600).contains(http.statusCode) { return nil }
            } catch {
                // Network error: fall through to retry.
            }
            guard attempt < Self.retryDelays.count else { return nil }
            try? await sleep(Self.retryDelays[attempt])
        }
        return nil
    }
}

import Foundation
import SwiftData

/// Saves imported recipes, skipping ones already saved from the same webpage.
@MainActor
struct RecipeSaver {
    /// Saves immediately. If a Recipe with the same webpage Source URL exists,
    /// returns that one instead of inserting a duplicate.
    @discardableResult
    func save(_ imported: ImportedRecipe, in context: ModelContext) throws -> Recipe {
        if let url = imported.sourceURL {
            let recipes = try context.fetch(FetchDescriptor<Recipe>())
            if let existing = recipes.first(where: {
                $0.source?.kind == .webpage && $0.source?.url == url
            }) {
                return existing
            }
        }
        let recipe = Recipe(imported)
        context.insert(recipe)
        try context.save()
        return recipe
    }
}

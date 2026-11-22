import Foundation
import SwiftData

/// The add-a-Recipe form's fields, and the logic that turns them into a Recipe.
/// Ingredients and Steps are typed one per line in a single text box each.
struct RecipeDraft: Equatable {
    var title = ""
    var ingredientsText = ""
    var stepsText = ""
    var photo: Data?

    /// The title with surrounding whitespace removed.
    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// One Ingredient per non-blank line, bullets and numbers removed, in typed order.
    var ingredients: [String] { Self.lines(of: ingredientsText) }

    /// One Step per non-blank line, bullets and numbers removed, in typed order.
    var steps: [String] { Self.lines(of: stepsText) }

    /// True when anything other than whitespace was typed, or a photo was chosen.
    var hasContent: Bool {
        !trimmedTitle.isEmpty || !ingredients.isEmpty || !steps.isEmpty || photo != nil
    }

    /// A Recipe needs a real word in its title. Everything else is optional.
    var canSave: Bool { !trimmedTitle.isEmpty }

    /// Saves a new Recipe with no Source, or returns nil when `canSave` is false.
    @MainActor
    @discardableResult
    func save(in context: ModelContext, at date: Date = .now) -> Recipe? {
        guard canSave else { return nil }
        let recipe = Recipe(
            title: trimmedTitle,
            ingredients: ingredients,
            steps: steps,
            photo: photo,
            savedDate: date
        )
        context.insert(recipe)
        return recipe
    }

    private static func lines(of text: String) -> [String] {
        text.split(whereSeparator: \.isNewline)
            .map { RecipeTextParser.stripListMarker($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { !$0.isEmpty }
    }
}

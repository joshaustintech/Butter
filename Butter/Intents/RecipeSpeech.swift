import Foundation

/// Turns saved Recipes into the sentence Siri reads aloud.
enum RecipeSpeech {
    static func findAnswer(recipes: [Recipe], text: String) -> String {
        let matches = RecipeSearch.search(recipes: recipes, matching: text)
        return RecipeSearch.spokenAnswer(for: matches, noun: "recipes")
    }

    static func recentAnswer(
        recipes: [Recipe],
        range: SavedRange,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        let saved = RecipeSearch.saved(in: range, recipes: recipes, now: now, calendar: calendar)
        return RecipeSearch.spokenAnswer(for: saved, noun: "recipes")
    }
}

import Foundation

/// How far back a "what did I save" question looks.
enum SavedRange: Sendable {
    case today
    case lastWeek
    case lastMonth
}

/// Pure logic behind Siri-style questions about saved Recipes.
enum RecipeSearch {
    /// Maximum number of titles read aloud.
    static let spokenLimit = 5

    /// Recipes whose title or any Ingredient matches `text`, ignoring case and
    /// diacritics. Title matches come first; each group keeps its input order.
    static func search(recipes: [Recipe], matching text: String) -> [Recipe] {
        let query = fold(text).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        var titleMatches: [Recipe] = []
        var ingredientMatches: [Recipe] = []
        for recipe in recipes {
            if fold(recipe.title).contains(query) {
                titleMatches.append(recipe)
            } else if (recipe.ingredients ?? []).contains(where: { fold($0.text).contains(query) }) {
                ingredientMatches.append(recipe)
            }
        }
        return titleMatches + ingredientMatches
    }

    /// Recipes saved in `range` ending at `now`, newest first.
    static func saved(
        in range: SavedRange,
        recipes: [Recipe],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [Recipe] {
        let start: Date
        switch range {
        case .today:
            start = calendar.startOfDay(for: now)
        case .lastWeek:
            start = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .lastMonth:
            start = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        }
        return recipes
            .filter { $0.savedDate >= start && $0.savedDate <= now }
            .sorted { $0.savedDate > $1.savedDate }
    }

    /// A natural-speech answer, e.g. "You have 3 recipes: A, B and C."
    /// `noun` is a phrase such as "recipes" (pluralised by the caller's wording;
    /// a single result uses the singular form with a trailing "s" removed).
    static func spokenAnswer(for recipes: [Recipe], noun: String) -> String {
        let titles = recipes.map { $0.title.isEmpty ? "Untitled" : $0.title }
        switch titles.count {
        case 0:
            return "I couldn't find any \(noun). Try another search."
        case 1:
            return "You have 1 \(singular(noun)): \(titles[0])."
        case 2...spokenLimit:
            let head = titles.dropLast().joined(separator: ", ")
            return "You have \(titles.count) \(noun): \(head) and \(titles[titles.count - 1])."
        default:
            let shown = titles.prefix(spokenLimit).joined(separator: ", ")
            let more = titles.count - spokenLimit
            return "You have \(titles.count) \(noun): \(shown), and \(more) more."
        }
    }

    private static func fold(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    private static func singular(_ noun: String) -> String {
        noun.hasSuffix("s") ? String(noun.dropLast()) : noun
    }
}

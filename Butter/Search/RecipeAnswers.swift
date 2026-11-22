import Foundation

/// How far back a "what did I save" question looks.
enum SavedRange: String, CaseIterable, Sendable {
    case today
    case lastWeek
    case lastMonth
}

/// A question a person can ask about their saved Recipes.
enum RecipeQuestion: Sendable {
    case find(String)
    case saved(SavedRange)
}

/// Answers questions about saved Recipes as the short sentence Siri reads aloud.
enum RecipeAnswers {
    /// Maximum number of titles read aloud.
    private static let spokenLimit = 5

    /// e.g. "You have 3 recipes: A, B and C."
    static func answer(
        to question: RecipeQuestion,
        from recipes: [Recipe],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        let matches: [Recipe]
        switch question {
        case .find(let text): matches = search(recipes, matching: text)
        case .saved(let range): matches = saved(recipes, in: range, now: now, calendar: calendar)
        }
        return sentence(for: matches)
    }

    /// Recipes whose title or any Ingredient matches `text`, ignoring case and
    /// diacritics. Title matches come first; each group keeps its input order.
    private static func search(_ recipes: [Recipe], matching text: String) -> [Recipe] {
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
    private static func saved(
        _ recipes: [Recipe],
        in range: SavedRange,
        now: Date,
        calendar: Calendar
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

    private static func sentence(for recipes: [Recipe]) -> String {
        let titles = recipes.map { $0.title.isEmpty ? "Untitled" : $0.title }
        switch titles.count {
        case 0:
            return "I couldn't find any recipes. Try another search."
        case 1:
            return "You have 1 recipe: \(titles[0])."
        case 2...spokenLimit:
            let head = titles.dropLast().joined(separator: ", ")
            return "You have \(titles.count) recipes: \(head) and \(titles[titles.count - 1])."
        default:
            let shown = titles.prefix(spokenLimit).joined(separator: ", ")
            return "You have \(titles.count) recipes: \(shown), and \(titles.count - spokenLimit) more."
        }
    }

    private static func fold(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

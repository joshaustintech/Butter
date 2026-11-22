import Foundation

/// What the list needs to know to sort, search and tint a recipe.
protocol Catalogued: Identifiable where ID == UUID {
    var title: String { get }
    var createdAt: Date { get }
}

enum RecipeSort: String, CaseIterable, Identifiable {
    case latest, name

    var id: Self { self }

    var label: String {
        switch self {
        case .latest: "Latest"
        case .name: "Name"
        }
    }
}

/// The tile colours a recipe can wear in the list.
enum TileTint: CaseIterable {
    case sage, butter, rose

    var palette: Palette {
        switch self {
        case .sage: .tintSage
        case .butter: .tintButter
        case .rose: .tintRose
        }
    }
}

enum RecipeCatalog {
    /// Recipes whose title contains `query` (ignoring case and diacritics),
    /// newest first for `.latest` or A→Z for `.name`.
    static func arrange<R: Catalogued>(_ recipes: [R], by sort: RecipeSort, matching query: String) -> [R] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = query.isEmpty ? recipes : recipes.filter { $0.title.localizedStandardContains(query) }
        switch sort {
        case .latest:
            return matches.sorted { $0.createdAt > $1.createdAt }
        case .name:
            return matches.sorted {
                switch $0.title.localizedCompare($1.title) {
                case .orderedAscending: true
                case .orderedDescending: false
                case .orderedSame: $0.createdAt > $1.createdAt
                }
            }
        }
    }

    /// Sage, butter, rose, repeating, in the order recipes were created, so a
    /// recipe keeps its colour whatever the sort and as newer recipes arrive.
    static func tints<R: Catalogued>(for recipes: [R]) -> [UUID: TileTint] {
        let oldestFirst = recipes.sorted { $0.createdAt < $1.createdAt }
        let cycle = TileTint.allCases
        return Dictionary(uniqueKeysWithValues: oldestFirst.enumerated().map { ($1.id, cycle[$0 % cycle.count]) })
    }

    /// `6 recipes · sorted by latest`.
    static func subtitle(count: Int, sort: RecipeSort) -> String {
        "\(count) \(count == 1 ? "recipe" : "recipes") · sorted by \(sort.label.lowercased())"
    }
}

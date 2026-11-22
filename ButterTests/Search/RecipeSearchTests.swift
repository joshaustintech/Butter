import Foundation
import SwiftData
import Testing
@testable import Butter

@MainActor
struct RecipeSearchTests {
    func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Recipe.self, Ingredient.self, Step.self, Source.self,
            configurations: config
        )
        return ModelContext(container)
    }

    func recipe(_ title: String, _ ingredients: [String] = [], saved: Date = .now, in context: ModelContext) -> Recipe {
        let r = Recipe(title: title, ingredients: ingredients, savedDate: saved)
        context.insert(r)
        return r
    }

    @Test func searchIsCaseAndDiacriticInsensitiveAndRanksTitlesFirst() throws {
        let context = try makeContext()
        let stew = recipe("Beef Stew", ["2 carrots"], in: context)
        let cake = recipe("Crème brûlée", ["cream"], in: context)
        let soup = recipe("Carrot Soup", ["stock"], in: context)
        let results = RecipeSearch.search(recipes: [stew, cake, soup], matching: "CARROT")
        #expect(results.map(\.title) == ["Carrot Soup", "Beef Stew"])
        #expect(RecipeSearch.search(recipes: [cake], matching: "creme").count == 1)
        #expect(RecipeSearch.search(recipes: [cake], matching: "  ").isEmpty)
    }

    @Test func savedRangesFilterAndSortNewestFirst() throws {
        let context = try makeContext()
        let cal = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let day: TimeInterval = 86_400
        let a = recipe("A", saved: now.addingTimeInterval(-3_600), in: context)
        let b = recipe("B", saved: now.addingTimeInterval(-3 * day), in: context)
        let c = recipe("C", saved: now.addingTimeInterval(-20 * day), in: context)
        let d = recipe("D", saved: now.addingTimeInterval(-90 * day), in: context)
        let all = [d, c, b, a]
        #expect(RecipeSearch.saved(in: .lastWeek, recipes: all, now: now, calendar: cal).map(\.title) == ["A", "B"])
        #expect(RecipeSearch.saved(in: .lastMonth, recipes: all, now: now, calendar: cal).map(\.title) == ["A", "B", "C"])
        let today = RecipeSearch.saved(in: .today, recipes: all, now: now, calendar: cal)
        #expect(today.allSatisfy { cal.isDate($0.savedDate, inSameDayAs: now) })
    }

    @Test func spokenAnswerFormats() throws {
        let context = try makeContext()
        let rs = ["A", "B", "C", "D", "E", "F", "G"].map { recipe($0, in: context) }
        #expect(RecipeSearch.spokenAnswer(for: Array(rs[0..<3]), noun: "recipes") == "You have 3 recipes: A, B and C.")
        #expect(RecipeSearch.spokenAnswer(for: Array(rs[0..<1]), noun: "recipes") == "You have 1 recipe: A.")
        #expect(RecipeSearch.spokenAnswer(for: rs, noun: "recipes") == "You have 7 recipes: A, B, C, D, E, and 2 more.")
        #expect(RecipeSearch.spokenAnswer(for: [], noun: "recipes").contains("couldn't find any recipes"))
    }
}

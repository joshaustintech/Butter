import Foundation
import SwiftData
import Testing
@testable import Butter

@MainActor
struct RecipeModelTests {
    func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Recipe.self, Ingredient.self, Step.self, Source.self,
            configurations: config
        )
        return ModelContext(container)
    }

    @Test func orderedAccessorsSortByPosition() throws {
        let context = try makeContext()
        let recipe = Recipe(title: "Toast")
        recipe.ingredients = [
            Ingredient(text: "butter", position: 2),
            Ingredient(text: "bread", position: 0),
            Ingredient(text: "salt", position: 1),
        ]
        recipe.steps = [
            Step(text: "eat", position: 1),
            Step(text: "toast", position: 0),
        ]
        context.insert(recipe)
        try context.save()
        #expect(recipe.orderedIngredients.map(\.text) == ["bread", "salt", "butter"])
        #expect(recipe.orderedSteps.map(\.text) == ["toast", "eat"])
    }

    @Test func touchUpdatesOnlyUpdatedDate() {
        let saved = Date(timeIntervalSince1970: 1_000)
        let recipe = Recipe(title: "Soup", savedDate: saved)
        #expect(recipe.updatedDate == saved)
        let later = Date(timeIntervalSince1970: 5_000)
        recipe.touch(at: later)
        #expect(recipe.savedDate == saved)
        #expect(recipe.updatedDate == later)
    }

    @Test func importedRecipeWithURLGetsWebpageSource() throws {
        let context = try makeContext()
        let url = URL(string: "https://example.com/pie")!
        let imported = ImportedRecipe(
            title: "Pie", ingredients: ["flour", "apples"], steps: ["mix", "bake"],
            sourceURL: url, imageURL: nil
        )
        let recipe = Recipe(imported)
        context.insert(recipe)
        try context.save()
        #expect(recipe.title == "Pie")
        #expect(recipe.orderedIngredients.map(\.text) == ["flour", "apples"])
        #expect(recipe.orderedIngredients.map(\.position) == [0, 1])
        #expect(recipe.orderedSteps.map(\.text) == ["mix", "bake"])
        #expect(recipe.source?.kind == .webpage)
        #expect(recipe.source?.url == url)
    }

    @Test func importedRecipeWithoutURLHasNoSource() {
        let imported = ImportedRecipe(
            title: "Tea", ingredients: [], steps: [], sourceURL: nil, imageURL: nil
        )
        #expect(Recipe(imported).source == nil)
    }

    @Test func photographedPageSource() {
        let data = Data([1, 2, 3])
        let source = Source(photographedPage: data)
        #expect(source.kind == .photographedPage)
        #expect(source.pageImage == data)
        #expect(source.url == nil)
    }

    @Test func deletingRecipeCascades() throws {
        let context = try makeContext()
        let recipe = Recipe(
            title: "Rice", ingredients: ["rice"], steps: ["boil"],
            source: Source(webpage: URL(string: "https://example.com")!)
        )
        context.insert(recipe)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<Ingredient>()) == 1)
        context.delete(recipe)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<Recipe>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Ingredient>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Step>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Source>()) == 0)
    }

    @Test func inversesAreSet() throws {
        let context = try makeContext()
        let recipe = Recipe(title: "Egg", ingredients: ["egg"], steps: ["fry"])
        context.insert(recipe)
        try context.save()
        #expect(recipe.orderedIngredients.first?.recipe === recipe)
        #expect(recipe.orderedSteps.first?.recipe === recipe)
    }
}

import Foundation
import SwiftData
import Testing
@testable import Butter

@MainActor
struct RecipeSaverTests {
    private func imported(_ url: String?) -> ImportedRecipe {
        ImportedRecipe(
            title: "Toast",
            ingredients: ["bread", "butter"],
            steps: ["Toast", "Spread"],
            sourceURL: url.flatMap(URL.init(string:)),
            imageURL: nil
        )
    }

    @Test func savesRecipe() throws {
        let container = try makeContainer(inMemory: true)
        let context = container.mainContext
        let recipe = try RecipeSaver().save(imported("https://example.com/a"), in: context)
        #expect(try context.fetch(FetchDescriptor<Recipe>()).count == 1)
        #expect(recipe.orderedIngredients.count == 2)
    }

    @Test func skipsDuplicateSourceURL() throws {
        let container = try makeContainer(inMemory: true)
        let context = container.mainContext
        let first = try RecipeSaver().save(imported("https://example.com/a"), in: context)
        let second = try RecipeSaver().save(imported("https://example.com/a"), in: context)
        #expect(first === second)
        #expect(try context.fetch(FetchDescriptor<Recipe>()).count == 1)
    }

    @Test func differentURLsBothSave() throws {
        let container = try makeContainer(inMemory: true)
        let context = container.mainContext
        _ = try RecipeSaver().save(imported("https://example.com/a"), in: context)
        _ = try RecipeSaver().save(imported("https://example.com/b"), in: context)
        #expect(try context.fetch(FetchDescriptor<Recipe>()).count == 2)
    }
}

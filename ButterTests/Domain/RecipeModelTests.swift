import Foundation
import SwiftData
import Testing
@testable import Butter

@MainActor
struct RecipeModelTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        container = try ModelContainer(
            for: Recipe.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func galette() throws -> RecipeContent {
        var content = RecipeContent(title: try #require(NonBlankText("Rhubarb Galette")))
        content.prepMinutes = WholeNumber(30)
        content.bakeMinutes = WholeNumber(50)
        content.servings = WholeNumber(6)
        content.detailOrder = try #require(DetailOrder([.bake, .prep, .serves]))
        content.rating = Rating(4.5)
        content.ingredients = ["flour", "butter", "rhubarb"].compactMap(NonBlankText.init)
        content.steps = ["Rub.", "Fold.", "Bake."].compactMap(NonBlankText.init)
        content.reviewNotes = NonBlankText("Next time, orange zest.")
        content.photo = Data([0xFF, 0xD8])
        return content
    }

    @Test func persistsAndReadsBackTypedContent() throws {
        let content = try galette()
        let created = Date(timeIntervalSince1970: 1_000)
        context.insert(Recipe(content: content, createdAt: created))
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<Recipe>()).first)
        #expect(fetched.content == content)
        #expect(fetched.createdAt == created)
        #expect(fetched.title == "Rhubarb Galette")
    }

    @Test func persistsTheSpecFieldsAsPlainValues() throws {
        let recipe = Recipe(content: try galette())
        #expect(recipe.prepMinutes == 30)
        #expect(recipe.bakeMinutes == 50)
        #expect(recipe.servings == 6)
        #expect(recipe.rating == 4.5)
        #expect(recipe.detailOrder == [.bake, .prep, .serves])
        #expect(recipe.ingredients == ["flour", "butter", "rhubarb"])
        #expect(recipe.steps == ["Rub.", "Fold.", "Bake."])
        #expect(recipe.reviewNotes == "Next time, orange zest.")
    }

    @Test func editingReplacesContentButKeepsIdentityAndCreationDate() throws {
        let recipe = Recipe(content: try galette(), createdAt: Date(timeIntervalSince1970: 5))
        context.insert(recipe)
        let id = recipe.id

        let edited = RecipeContent(title: try #require(NonBlankText("Plain Galette")))
        recipe.content = edited
        try context.save()

        #expect(recipe.content == edited)
        #expect(recipe.id == id)
        #expect(recipe.createdAt == Date(timeIntervalSince1970: 5))
        #expect(recipe.rating == nil)
        #expect(recipe.ingredients.isEmpty)
    }

    @Test func eachRecipeHasItsOwnIdentity() throws {
        let content = try galette()
        #expect(Recipe(content: content).id != Recipe(content: content).id)
    }

    @Test func aDeletedRecipeReportsItIsGone() throws {
        let recipe = Recipe(content: try galette())
        context.insert(recipe)
        try context.save()
        #expect(!recipe.isGone)

        context.delete(recipe)
        #expect(recipe.isGone)
        try context.save()
        #expect(recipe.isGone)
        #expect(try context.fetchCount(FetchDescriptor<Recipe>()) == 0)
    }
}

import Foundation
import SwiftData
import Testing
@testable import Butter

@MainActor
struct RecipeDraftTests {
    private let now = Date(timeIntervalSince1970: 1_000)

    private func save(_ draft: RecipeDraft, in context: ModelContext) throws -> Recipe {
        try #require(draft.save(in: context, at: now))
    }

    @Test func titleOnlyRecipeIsSaved() throws {
        let container = try makeContainer(inMemory: true)
        defer { withExtendedLifetime(container) {} }
        let recipe = try save(RecipeDraft(title: "  Toast "), in: container.mainContext)

        #expect(recipe.title == "Toast")
        #expect(recipe.orderedIngredients.isEmpty)
        #expect(recipe.orderedSteps.isEmpty)
        #expect(recipe.photo == nil)
    }

    @Test func ingredientsAndStepsKeepTypedOrder() throws {
        let container = try makeContainer(inMemory: true)
        defer { withExtendedLifetime(container) {} }
        let draft = RecipeDraft(title: "Pancakes", ingredientsText: "2 eggs\n1 cup flour\nmilk",
                                stepsText: "Whisk.\nCook.\nServe.")
        let recipe = try save(draft, in: container.mainContext)

        #expect(recipe.orderedIngredients.map(\.text) == ["2 eggs", "1 cup flour", "milk"])
        #expect(recipe.orderedSteps.map(\.text) == ["Whisk.", "Cook.", "Serve."])
    }

    @Test func blankLinesAreDropped() {
        let draft = RecipeDraft(title: "T", ingredientsText: "\n a \n\n   \nb\n", stepsText: "\n\nOne\n \n")
        #expect(draft.ingredients == ["a", "b"])
        #expect(draft.steps == ["One"])
    }

    @Test func bulletsAndNumbersAreStripped() {
        let draft = RecipeDraft(
            title: "T",
            ingredientsText: "- 2 eggs\n• 1 cup flour\n1.5 cups milk",
            stepsText: "1. Mix\n2) Bake\nStep 3: Eat"
        )
        #expect(draft.ingredients == ["2 eggs", "1 cup flour", "1.5 cups milk"])
        #expect(draft.steps == ["Mix", "Bake", "Eat"])
    }

    @Test func whitespaceOnlyTitleCannotBeSaved() throws {
        let container = try makeContainer(inMemory: true)
        defer { withExtendedLifetime(container) {} }
        let draft = RecipeDraft(title: "  \n ", ingredientsText: "eggs")

        #expect(!draft.canSave)
        #expect(draft.save(in: container.mainContext, at: now) == nil)
        #expect(try container.mainContext.fetch(FetchDescriptor<Recipe>()).isEmpty)
    }

    @Test func titleWithAWordCanBeSaved() {
        #expect(RecipeDraft(title: " Soup ").canSave)
    }

    @Test func hasContentForAnyFieldOrPhoto() {
        #expect(!RecipeDraft().hasContent)
        #expect(RecipeDraft(title: "a").hasContent)
        #expect(RecipeDraft(ingredientsText: "a").hasContent)
        #expect(RecipeDraft(stepsText: "a").hasContent)
        #expect(RecipeDraft(photo: Data([1])).hasContent)
    }

    @Test func whitespaceOnlyFieldsAreNotContent() {
        #expect(!RecipeDraft(title: "  \n").hasContent)
        #expect(!RecipeDraft(ingredientsText: " \n\t ").hasContent)
        #expect(!RecipeDraft(stepsText: "\n\n").hasContent)
    }

    @Test func savedRecipeHasNoSourceAndDatesAreSet() throws {
        let container = try makeContainer(inMemory: true)
        defer { withExtendedLifetime(container) {} }
        let recipe = try save(RecipeDraft(title: "Soup", photo: Data([1, 2])), in: container.mainContext)

        #expect(recipe.source == nil)
        #expect(recipe.savedDate == now)
        #expect(recipe.updatedDate == now)
        #expect(recipe.photo == Data([1, 2]))
    }

    @Test func sameTitleTwiceKeepsBoth() throws {
        let container = try makeContainer(inMemory: true)
        defer { withExtendedLifetime(container) {} }
        let context = container.mainContext
        _ = try save(RecipeDraft(title: "Soup"), in: context)
        _ = try save(RecipeDraft(title: "Soup"), in: context)

        #expect(try context.fetch(FetchDescriptor<Recipe>()).count == 2)
    }
}

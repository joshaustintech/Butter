import Foundation
import SwiftData
import Testing
import SwiftUI
@testable import Butter

@MainActor
struct RecipeDetailTests {
    @Test func recipeDetailViewInitializesWithFullRecipe() {
        let photoData = Data([0xDE, 0xAD, 0xBE, 0xEF])
        let recipe = Recipe(
            title: "Lemon pancakes",
            ingredients: ["2 eggs", "1 cup flour"],
            steps: ["Mix ingredients", "Cook on griddle"],
            photo: photoData,
            source: Source(webpage: URL(string: "https://example.com/pancakes")!)
        )
        let view = RecipeDetailView(recipe: recipe)

        #expect(view.recipe.title == "Lemon pancakes")
        #expect(view.recipe.photo == photoData)
        #expect(view.recipe.orderedIngredients.map(\.text) == ["2 eggs", "1 cup flour"])
        #expect(view.recipe.orderedSteps.map(\.text) == ["Mix ingredients", "Cook on griddle"])
        #expect(view.recipe.source?.kind == .webpage)
        #expect(view.recipe.source?.url?.host == "example.com")
    }

    @Test func recipeDetailViewInitializesWithTitleOnlyRecipe() {
        let recipe = Recipe(title: "Simple Toast")
        let view = RecipeDetailView(recipe: recipe)

        #expect(view.recipe.title == "Simple Toast")
        #expect(view.recipe.orderedIngredients.isEmpty)
        #expect(view.recipe.orderedSteps.isEmpty)
        #expect(view.recipe.photo == nil)
        #expect(view.recipe.source == nil)
    }

    @Test func recipeDetailViewHandlesPhotographedPageSource() {
        let pageData = Data([0x01, 0x02, 0x03])
        let recipe = Recipe(
            title: "Cookbook Card",
            ingredients: ["1 cup sugar"],
            steps: ["Caramelize"],
            source: Source(photographedPage: pageData)
        )
        let view = RecipeDetailView(recipe: recipe)

        #expect(view.recipe.source?.kind == .photographedPage)
        #expect(view.recipe.source?.url == nil)
        #expect(view.recipe.source?.pageImage == pageData)
    }
}

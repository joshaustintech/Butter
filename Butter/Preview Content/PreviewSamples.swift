#if DEBUG
import Foundation
import SwiftData

/// The mockup's sample recipes, for previews only. Never seeded into the app.
@MainActor
enum PreviewSamples {
    static let galette = content(
        "Rhubarb Galette", prep: 30, bake: 50, servings: 6, rating: 5,
        ingredients: [
            "1¼ cups all-purpose flour", "½ cup cold butter, cubed", "3 tbsp ice water",
            "1 lb rhubarb, sliced", "⅓ cup sugar", "1 tbsp cornstarch", "1 egg, beaten",
        ],
        steps: [
            "Rub the butter into the flour until crumbly, then add ice water and bring together. Chill for 30 minutes.",
            "Toss the rhubarb with sugar and cornstarch.",
            "Roll the dough into a rough round, pile the filling in the centre and fold the edges over.",
            "Brush with egg and bake at 400°F until golden, about 50 minutes.",
        ],
        review: "Tart and sweet in just the right measure. Next time, a little orange zest in the crust."
    )

    static let sandwich = content(
        "Roast Turkey & Apple Sandwich", prep: 10, servings: 2, rating: 4.5,
        ingredients: [
            "4 slices sourdough", "6 oz roast turkey", "½ crisp apple, thinly sliced",
            "2 tbsp whole-grain mustard", "Handful of arugula",
        ],
        steps: ["Spread mustard on all four slices.", "Layer turkey, apple and arugula, then close and halve."]
    )

    static let bare = content("Radish & Chive Butter")

    /// Newest first, as the list shows them under Latest.
    static let catalog: [RecipeContent] = [
        sandwich,
        content("Lemon Ricotta Pancakes", prep: 10, bake: 15, rating: 4.5),
        content("Rhubarb Galette", prep: 30, bake: 50, servings: 6, rating: 5),
        content("Herb Garden Focaccia", prep: 30, bake: 150, rating: 4),
        content("Honey Oat Scones", prep: 15, bake: 25, rating: 4.5),
        bare,
    ]

    static let addedDate = Date(timeIntervalSince1970: 1_795_000_000)

    static let container: ModelContainer = makeContainer(with: catalog)
    static let emptyContainer: ModelContainer = makeContainer(with: [])

    /// Every saved recipe in `container`.
    static var recipes: [Recipe] {
        (try? container.mainContext.fetch(FetchDescriptor<Recipe>())) ?? []
    }

    /// A saved recipe from `container`, for views that take a model.
    static func recipe(titled title: String = "Rhubarb Galette") -> Recipe {
        if let recipe = recipes.first(where: { $0.title == title }) { return recipe }
        let recipe = Recipe(content: galette)
        container.mainContext.insert(recipe)
        return recipe
    }

    static func draft(_ content: RecipeContent = galette) -> RecipeDraft {
        RecipeDraft(content)
    }

    private static func makeContainer(with contents: [RecipeContent]) -> ModelContainer {
        // Previews can't run without a store, so a failure here is a programming error.
        let container = try! ModelContainer(
            for: Recipe.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        for (age, content) in contents.enumerated() {
            let created = addedDate.addingTimeInterval(-Double(age) * 86_400)
            container.mainContext.insert(Recipe(content: content, createdAt: created))
        }
        return container
    }

    private static func content(
        _ title: String,
        prep: Int? = nil,
        bake: Int? = nil,
        servings: Int? = nil,
        rating: Double? = nil,
        ingredients: [String] = [],
        steps: [String] = [],
        review: String? = nil
    ) -> RecipeContent {
        var content = RecipeContent(title: NonBlankText(title)!)
        content.prepMinutes = prep.flatMap(WholeNumber.init)
        content.bakeMinutes = bake.flatMap(WholeNumber.init)
        content.servings = servings.flatMap(WholeNumber.init)
        content.rating = rating.flatMap(Rating.init)
        content.ingredients = ingredients.compactMap(NonBlankText.init)
        content.steps = steps.compactMap(NonBlankText.init)
        content.reviewNotes = review.flatMap(NonBlankText.init)
        return content
    }
}
#endif

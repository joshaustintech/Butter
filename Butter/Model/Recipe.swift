import Foundation
import SwiftData

/// A saved dish: a title, its Ingredients, its ordered Steps, an optional photo,
/// an optional Source, and the dates it was saved and last updated.
///
/// CloudKit-compatible: every property has a default or is optional, there are
/// no unique constraints, and relationships are optional with explicit inverses.
@Model
final class Recipe {
    var title: String = ""
    /// When the Recipe was first added to Butter. Set once at init.
    var savedDate: Date = Date.now
    /// When the Recipe was last changed. Call `touch()` after a change.
    var updatedDate: Date = Date.now
    @Attribute(.externalStorage) var photo: Data?

    @Relationship(deleteRule: .cascade, inverse: \Ingredient.recipe)
    var ingredients: [Ingredient]?

    @Relationship(deleteRule: .cascade, inverse: \Step.recipe)
    var steps: [Step]?

    @Relationship(deleteRule: .cascade, inverse: \Source.recipe)
    var source: Source?

    init(
        title: String = "",
        ingredients: [String] = [],
        steps: [String] = [],
        photo: Data? = nil,
        source: Source? = nil,
        savedDate: Date = Date.now
    ) {
        self.title = title
        self.savedDate = savedDate
        self.updatedDate = savedDate
        self.photo = photo
        self.ingredients = ingredients.enumerated().map { Ingredient(text: $1, position: $0) }
        self.steps = steps.enumerated().map { Step(text: $1, position: $0) }
        self.source = source
    }

    /// Creates a Recipe from one read by an importer. A webpage Source is
    /// attached when the imported recipe has a source address.
    convenience init(_ imported: ImportedRecipe, savedDate: Date = Date.now) {
        self.init(
            title: imported.title,
            ingredients: imported.ingredients,
            steps: imported.steps,
            source: imported.sourceURL.map { Source(webpage: $0) },
            savedDate: savedDate
        )
    }

    /// Ingredients in their saved order.
    var orderedIngredients: [Ingredient] {
        (ingredients ?? []).sorted { $0.position < $1.position }
    }

    /// Steps in their saved order.
    var orderedSteps: [Step] {
        (steps ?? []).sorted { $0.position < $1.position }
    }

    /// Marks the Recipe as changed now.
    func touch(at date: Date = Date.now) {
        updatedDate = date
    }
}

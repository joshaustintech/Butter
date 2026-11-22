import Foundation
import SwiftData

/// A saved recipe. Fields are persisted as plain values but can only be
/// written through `content`, which accepts nothing but validated values.
@Model
final class Recipe {
    @Attribute(.unique) private(set) var id: UUID
    private(set) var createdAt: Date
    private(set) var title: String
    @Attribute(.externalStorage) private(set) var photo: Data? = nil
    private(set) var prepMinutes: Int? = nil
    private(set) var bakeMinutes: Int? = nil
    private(set) var servings: Int? = nil
    private var detailOrderStorage: String
    private var ratingHalfStars: Int? = nil
    private(set) var ingredients: [String]
    private(set) var steps: [String]
    private(set) var reviewNotes: String? = nil

    init(content: RecipeContent, createdAt: Date = .now) {
        id = UUID()
        self.createdAt = createdAt
        title = content.title.value
        detailOrderStorage = DetailOrder.standard.storage
        ingredients = []
        steps = []
        self.content = content
    }

    var detailOrder: [DetailKind] { DetailOrder(storage: detailOrderStorage).kinds }

    var rating: Double? { ratingHalfStars.flatMap(Rating.init(halfStars:))?.value }

    var content: RecipeContent {
        get {
            // The stored title is only ever written from a `NonBlankText`.
            var content = RecipeContent(title: NonBlankText(title) ?? NonBlankText("Untitled")!)
            content.photo = photo
            content.prepMinutes = prepMinutes.flatMap(WholeNumber.init)
            content.bakeMinutes = bakeMinutes.flatMap(WholeNumber.init)
            content.servings = servings.flatMap(WholeNumber.init)
            content.detailOrder = DetailOrder(storage: detailOrderStorage)
            content.rating = ratingHalfStars.flatMap(Rating.init(halfStars:))
            content.ingredients = ingredients.compactMap(NonBlankText.init)
            content.steps = steps.compactMap(NonBlankText.init)
            content.reviewNotes = reviewNotes.flatMap(NonBlankText.init)
            return content
        }
        set {
            title = newValue.title.value
            photo = newValue.photo
            prepMinutes = newValue.prepMinutes?.value
            bakeMinutes = newValue.bakeMinutes?.value
            servings = newValue.servings?.value
            detailOrderStorage = newValue.detailOrder.storage
            ratingHalfStars = newValue.rating?.halfStars
            ingredients = newValue.ingredients.map(\.value)
            steps = newValue.steps.map(\.value)
            reviewNotes = newValue.reviewNotes?.value
        }
    }

    /// True once the recipe has been deleted, whether or not that is saved yet.
    var isGone: Bool { isDeleted || modelContext == nil }
}

extension Recipe: Catalogued {}

import Foundation

/// The editor's working copy of a recipe. It holds text exactly as typed;
/// numbers and the rating are already valid values. `content` is the only
/// way out, and it is `nil` until the title has something in it.
struct RecipeDraft: Equatable {
    struct Line: Identifiable, Equatable {
        let id = UUID()
        var text: String
    }

    var title = ""
    var photo: Data?
    var prepMinutes: WholeNumber?
    var bakeMinutes: WholeNumber?
    var servings: WholeNumber?
    var detailOrder = DetailOrder.standard
    var rating: Rating?
    var ingredients: [Line] = []
    var steps: [Line] = []
    var reviewNotes = ""

    init() {}

    init(_ content: RecipeContent) {
        title = content.title.value
        photo = content.photo
        prepMinutes = content.prepMinutes
        bakeMinutes = content.bakeMinutes
        servings = content.servings
        detailOrder = content.detailOrder
        rating = content.rating
        ingredients = content.ingredients.map { Line(text: $0.value) }
        steps = content.steps.map { Line(text: $0.value) }
        reviewNotes = content.reviewNotes?.value ?? ""
    }

    /// The validated recipe, with blank lines dropped; `nil` while the title is blank.
    var content: RecipeContent? {
        guard let title = NonBlankText(title) else { return nil }
        var content = RecipeContent(title: title)
        content.photo = photo
        content.prepMinutes = prepMinutes
        content.bakeMinutes = bakeMinutes
        content.servings = servings
        content.detailOrder = detailOrder
        content.rating = rating
        content.ingredients = ingredients.compactMap { NonBlankText($0.text) }
        content.steps = steps.compactMap { NonBlankText($0.text) }
        content.reviewNotes = NonBlankText(reviewNotes)
        return content
    }

    subscript(detail kind: DetailKind) -> WholeNumber? {
        get {
            switch kind {
            case .prep: prepMinutes
            case .bake: bakeMinutes
            case .serves: servings
            }
        }
        set {
            switch kind {
            case .prep: prepMinutes = newValue
            case .bake: bakeMinutes = newValue
            case .serves: servings = newValue
            }
        }
    }

    @discardableResult
    mutating func addIngredient() -> Line.ID {
        let line = Line(text: "")
        ingredients.append(line)
        return line.id
    }

    @discardableResult
    mutating func addStep() -> Line.ID {
        let line = Line(text: "")
        steps.append(line)
        return line.id
    }

    mutating func removeIngredient(id: Line.ID) {
        ingredients.removeAll { $0.id == id }
    }
}

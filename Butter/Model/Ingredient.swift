import Foundation
import SwiftData

/// One line of what a Recipe needs (e.g. "2 chicken thighs").
@Model
final class Ingredient {
    var text: String = ""
    /// Zero-based place in the Recipe's list of Ingredients.
    var position: Int = 0
    var recipe: Recipe?

    init(text: String = "", position: Int = 0) {
        self.text = text
        self.position = position
    }
}

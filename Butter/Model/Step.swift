import Foundation
import SwiftData

/// One ordered instruction in a Recipe's method.
@Model
final class Step {
    var text: String = ""
    /// Zero-based place in the Recipe's method.
    var position: Int = 0
    var recipe: Recipe?

    init(text: String = "", position: Int = 0) {
        self.text = text
        self.position = position
    }
}

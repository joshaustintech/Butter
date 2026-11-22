import Foundation

/// A Recipe as read from a Source, before it is saved. Plain value type so the
/// importers stay independent of SwiftData.
nonisolated struct ImportedRecipe: Equatable, Sendable {
    var title: String
    var ingredients: [String]
    var steps: [String]
    /// The webpage address, when the Source is a webpage.
    var sourceURL: URL?
    /// Address of a photo of the dish, when the page provides one.
    var imageURL: URL?
}

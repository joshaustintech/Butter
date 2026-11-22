import Foundation

/// Every way importing a Recipe can fail, each with a message a person can read.
nonisolated enum RecipeImportError: Error, Equatable, Sendable, LocalizedError {
    /// The address is not an http or https link.
    case notAWebpage
    /// The page could not be downloaded, or the server did not return a successful webpage response.
    case badResponse
    /// The page downloaded fine but has no schema.org Recipe in it.
    case noRecipeFound
    /// No text could be read from the photographed page.
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .notAWebpage: "This link is not a webpage address."
        case .badResponse: "The webpage could not be downloaded."
        case .noRecipeFound: "No recipe was found on this webpage."
        case .noTextFound: "No text could be read from this photo."
        }
    }
}

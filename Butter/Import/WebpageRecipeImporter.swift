import Foundation

/// Imports a Recipe from a webpage by downloading it and reading its JSON-LD metadata.
nonisolated struct WebpageRecipeImporter: Sendable {
    typealias Fetch = @Sendable (URL) async throws -> (Data, URLResponse)

    nonisolated enum ImportError: Error, Equatable, Sendable, LocalizedError {
        /// The address is not an http or https link.
        case notAWebpage
        /// The server did not return a successful webpage response.
        case badResponse
        /// The page downloaded fine but has no schema.org Recipe in it.
        case noRecipeFound

        var errorDescription: String? {
            switch self {
            case .notAWebpage: "This link is not a webpage address."
            case .badResponse: "The webpage could not be downloaded."
            case .noRecipeFound: "No recipe was found on this webpage."
            }
        }
    }

    let fetch: Fetch

    init(fetch: @escaping Fetch = WebpageRecipeImporter.liveFetch) {
        self.fetch = fetch
    }

    func importRecipe(from url: URL) async throws -> ImportedRecipe {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            throw ImportError.notAWebpage
        }

        let (data, response) = try await fetch(url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ImportError.badResponse
        }

        let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
        guard let recipe = RecipeJSONLDParser.parse(html: html, pageURL: http.url ?? url) else {
            throw ImportError.noRecipeFound
        }
        return recipe
    }

    private nonisolated static func liveFetch(_ url: URL) async throws -> (Data, URLResponse) {
        try await URLSession.shared.data(from: url)
    }
}

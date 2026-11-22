import Foundation

/// Imports a Recipe from a webpage by downloading it and reading its JSON-LD metadata.
nonisolated struct WebpageRecipeImporter: Sendable {
    typealias Fetch = @Sendable (URL) async throws -> (Data, URLResponse)

    let fetch: Fetch

    init(fetch: @escaping Fetch = WebpageRecipeImporter.liveFetch) {
        self.fetch = fetch
    }

    func importRecipe(from url: URL) async throws -> ImportedRecipe {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            throw RecipeImportError.notAWebpage
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await fetch(url)
        } catch {
            throw RecipeImportError.badResponse
        }
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw RecipeImportError.badResponse
        }

        let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
        guard let recipe = RecipeJSONLDParser.parse(html: html, pageURL: http.url ?? url) else {
            throw RecipeImportError.noRecipeFound
        }
        return recipe
    }

    nonisolated static func liveFetch(_ url: URL) async throws -> (Data, URLResponse) {
        try await URLSession.shared.data(from: url)
    }
}

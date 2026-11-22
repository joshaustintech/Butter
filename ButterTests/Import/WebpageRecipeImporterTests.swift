import Foundation
import Testing
@testable import Butter

struct WebpageRecipeImporterTests {
    private struct Unreachable: Error {}

    private let pageURL = URL(string: "https://example.com/recipes/pancakes")!

    private func page(_ json: String) -> Data {
        Data("<html><head><script type=\"application/ld+json\">\(json)</script></head><body></body></html>".utf8)
    }

    private func importer(status: Int = 200, body: Data) -> WebpageRecipeImporter {
        WebpageRecipeImporter { url in
            (body, HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!)
        }
    }

    private let pancakes = #"{"@type":"Recipe","name":"Pancakes","recipeIngredient":["1 cup flour","2 eggs"],"recipeInstructions":"Mix.\nCook."}"#

    @Test func importsRecipeFromSuccessfulPage() async throws {
        let recipe = try await importer(body: page(pancakes)).importRecipe(from: pageURL)
        #expect(recipe.title == "Pancakes")
        #expect(recipe.ingredients == ["1 cup flour", "2 eggs"])
        #expect(recipe.steps == ["Mix.", "Cook."])
        #expect(recipe.sourceURL == pageURL)
    }

    @Test func fetchesTheRequestedURL() async throws {
        let requested = URL(string: "https://example.com/a/b?c=d")!
        let importer = WebpageRecipeImporter { url in
            #expect(url == requested)
            return (Data(), HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        _ = try? await importer.importRecipe(from: requested)
    }

    @Test func httpSchemeIsAccepted() async throws {
        let url = URL(string: "http://example.com/pancakes")!
        let recipe = try await importer(body: page(pancakes)).importRecipe(from: url)
        #expect(recipe.title == "Pancakes")
    }

    @Test func nonWebSchemesAreRejectedWithoutFetching() async {
        let importer = WebpageRecipeImporter { _ in throw Unreachable() }
        for string in ["file:///tmp/recipe.html", "ftp://example.com/recipe", "mailto:a@example.com"] {
            await #expect(throws: WebpageRecipeImporter.ImportError.notAWebpage) {
                try await importer.importRecipe(from: URL(string: string)!)
            }
        }
    }

    @Test func serverErrorIsBadResponse() async {
        let importer = importer(status: 404, body: page(pancakes))
        await #expect(throws: WebpageRecipeImporter.ImportError.badResponse) {
            try await importer.importRecipe(from: pageURL)
        }
    }

    @Test func nonHTTPResponseIsBadResponse() async {
        let importer = WebpageRecipeImporter { url in
            (Data(), URLResponse(url: url, mimeType: "text/html", expectedContentLength: 0, textEncodingName: "utf-8"))
        }
        await #expect(throws: WebpageRecipeImporter.ImportError.badResponse) {
            try await importer.importRecipe(from: pageURL)
        }
    }

    @Test func fetchFailurePropagates() async {
        let importer = WebpageRecipeImporter { _ in throw Unreachable() }
        await #expect(throws: Unreachable.self) {
            try await importer.importRecipe(from: pageURL)
        }
    }

    @Test func pageWithoutRecipeIsNoRecipeFound() async {
        let body = Data(#"<html><script type="application/ld+json">{"@type":"WebSite","name":"Site"}</script></html>"#.utf8)
        await #expect(throws: WebpageRecipeImporter.ImportError.noRecipeFound) {
            try await importer(body: body).importRecipe(from: pageURL)
        }
    }

    @Test func pageWithoutAnyJSONLDIsNoRecipeFound() async {
        let body = Data("<html><body><h1>Pancakes</h1></body></html>".utf8)
        await #expect(throws: WebpageRecipeImporter.ImportError.noRecipeFound) {
            try await importer(body: body).importRecipe(from: pageURL)
        }
    }

    @Test func invalidUTF8FallsBackToISOLatin1() async throws {
        // 0xE8 is "è" in ISO Latin-1 and is not valid UTF-8 on its own.
        var body = Data(#"<script type="application/ld+json">{"@type":"Recipe","name":"Cr"#.utf8)
        body.append(0xE8)
        body.append(contentsOf: Data(#"me"}</script>"#.utf8))

        let recipe = try await importer(body: body).importRecipe(from: pageURL)
        #expect(recipe.title == "Cr\u{E8}me")
    }

    @Test func relativeImageIsResolvedAgainstPage() async throws {
        let json = #"{"@type":"Recipe","name":"Toast","image":"/images/toast.jpg"}"#
        let recipe = try await importer(body: page(json)).importRecipe(from: pageURL)
        #expect(recipe.imageURL == URL(string: "https://example.com/images/toast.jpg"))
    }
}

import Foundation
import SwiftData
import Testing
@testable import Butter

@MainActor
struct RecipeImporterTests {
    private struct Offline: Error {}

    private struct FakeRecognizer: DocumentTextRecognizing {
        var text: String
        func recognizeText(in imageData: Data) async throws -> String { text }
    }

    /// Records fetches and sleeps; serves canned responses per URL.
    private final class Network: @unchecked Sendable {
        var pages: [URL: (Int, Data)] = [:]
        /// Responses for the dish photo, consumed one per attempt; the last repeats.
        var photoAttempts: [Result<(Int, Data), Offline>] = []
        var fetched: [URL] = []
        var sleeps: [Duration] = []

        let photoURL = URL(string: "https://example.com/images/pancakes.jpg")!

        func fetch(_ url: URL) async throws -> (Data, URLResponse) {
            fetched.append(url)
            if url == photoURL {
                let index = min(fetched.filter { $0 == photoURL }.count - 1, photoAttempts.count - 1)
                switch photoAttempts[index] {
                case .success(let (status, data)): return (data, response(url, status))
                case .failure(let error): throw error
                }
            }
            guard let (status, data) = pages[url] else { throw Offline() }
            return (data, response(url, status))
        }

        private func response(_ url: URL, _ status: Int) -> URLResponse {
            HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
        }
    }

    private let pageURL = URL(string: "https://example.com/recipes/pancakes")!
    private let photoBytes = Data([9, 8, 7])

    private func html(image: Bool = true) -> Data {
        let imageField = image ? #","image":"/images/pancakes.jpg""# : ""
        return Data("""
        <html><script type="application/ld+json">{"@type":"Recipe","name":"Pancakes",\
        "recipeIngredient":["1 cup flour","2 eggs"],"recipeInstructions":"Mix.\\nCook."\(imageField)}</script></html>
        """.utf8)
    }

    private func make(
        _ network: Network, recognizerText: String = "Lemon Cake\nIngredients\n2 cups flour\n3 eggs"
    ) -> RecipeImporter {
        RecipeImporter(
            fetch: { try await network.fetch($0) },
            recognizer: FakeRecognizer(text: recognizerText),
            sleep: { network.sleeps.append($0) }
        )
    }

    private func recipes(_ context: ModelContext) throws -> [Recipe] {
        try context.fetch(FetchDescriptor<Recipe>())
    }

    // MARK: webpage

    @Test func newWebpageIsSavedWithWebpageSource() async throws {
        let network = Network()
        network.pages[pageURL] = (200, html(image: false))
        let context = try makeContainer(inMemory: true).mainContext

        let outcome = try await make(network).importRecipe(.webpage(pageURL), in: context)

        guard case .saved(let recipe) = outcome else { Issue.record("expected saved"); return }
        #expect(recipe.title == "Pancakes")
        #expect(recipe.orderedIngredients.map(\.text) == ["1 cup flour", "2 eggs"])
        #expect(recipe.orderedSteps.map(\.text) == ["Mix.", "Cook."])
        #expect(recipe.source?.kind == .webpage)
        #expect(recipe.source?.url == pageURL)
        #expect(try recipes(context).count == 1)
    }

    @Test func repeatedWebpageIsDuplicateOfExistingRecipe() async throws {
        let network = Network()
        network.pages[pageURL] = (200, html(image: false))
        let context = try makeContainer(inMemory: true).mainContext
        let importer = make(network)

        let first = try await importer.importRecipe(.webpage(pageURL), in: context)
        let second = try await importer.importRecipe(.webpage(pageURL), in: context)

        guard case .saved(let saved) = first, case .duplicate(let existing) = second else {
            Issue.record("expected saved then duplicate"); return
        }
        #expect(saved === existing)
        #expect(try recipes(context).count == 1)
    }

    @Test func dishPhotoIsSavedWithRecipe() async throws {
        let network = Network()
        network.pages[pageURL] = (200, html())
        network.photoAttempts = [.success((200, photoBytes))]
        let context = try makeContainer(inMemory: true).mainContext

        let outcome = try await make(network).importRecipe(.webpage(pageURL), in: context)

        guard case .saved(let recipe) = outcome else { Issue.record("expected saved"); return }
        #expect(recipe.photo == photoBytes)
    }

    @Test func dishPhotoIsRetriedAfterNetworkErrorThenServerError() async throws {
        let network = Network()
        network.pages[pageURL] = (200, html())
        network.photoAttempts = [.failure(Offline()), .success((503, Data())), .success((200, photoBytes))]
        let context = try makeContainer(inMemory: true).mainContext

        let outcome = try await make(network).importRecipe(.webpage(pageURL), in: context)

        guard case .saved(let recipe) = outcome else { Issue.record("expected saved"); return }
        #expect(recipe.photo == photoBytes)
        #expect(network.fetched.filter { $0 == network.photoURL }.count == 3)
        #expect(network.sleeps == [.seconds(1), .seconds(2)])
    }

    @Test func dishPhotoIsNotRetriedOnClientError() async throws {
        let network = Network()
        network.pages[pageURL] = (200, html())
        network.photoAttempts = [.success((404, Data()))]
        let context = try makeContainer(inMemory: true).mainContext

        let outcome = try await make(network).importRecipe(.webpage(pageURL), in: context)

        guard case .saved(let recipe) = outcome else { Issue.record("expected saved"); return }
        #expect(recipe.photo == nil)
        #expect(network.fetched.filter { $0 == network.photoURL }.count == 1)
        #expect(network.sleeps.isEmpty)
    }

    @Test func dishPhotoFailureStillSavesRecipeAfterThreeAttempts() async throws {
        let network = Network()
        network.pages[pageURL] = (200, html())
        network.photoAttempts = [.failure(Offline())]
        let context = try makeContainer(inMemory: true).mainContext

        let outcome = try await make(network).importRecipe(.webpage(pageURL), in: context)

        guard case .saved(let recipe) = outcome else { Issue.record("expected saved"); return }
        #expect(recipe.photo == nil)
        #expect(try recipes(context).count == 1)
        #expect(network.fetched.filter { $0 == network.photoURL }.count == 3)
    }

    @Test func pageDownloadIsNotRetried() async throws {
        let network = Network()
        network.pages[pageURL] = (503, Data())
        let context = try makeContainer(inMemory: true).mainContext

        await #expect(throws: RecipeImportError.badResponse) {
            try await make(network).importRecipe(.webpage(pageURL), in: context)
        }
        #expect(network.fetched == [pageURL])
        #expect(network.sleeps.isEmpty)
    }

    // MARK: photographed page

    @Test func photographedPageIsSavedWithPhotoAsSource() async throws {
        let network = Network()
        let context = try makeContainer(inMemory: true).mainContext
        let image = Data([1, 2, 3])

        let outcome = try await make(network).importRecipe(.photographedPage(image), in: context)

        guard case .saved(let recipe) = outcome else { Issue.record("expected saved"); return }
        #expect(recipe.title == "Lemon Cake")
        #expect(recipe.source?.kind == .photographedPage)
        #expect(recipe.source?.pageImage == image)
    }

    @Test func photographedPageIsNeverDuplicate() async throws {
        let network = Network()
        let context = try makeContainer(inMemory: true).mainContext
        let importer = make(network)
        let image = Data([1, 2, 3])

        _ = try await importer.importRecipe(.photographedPage(image), in: context)
        let second = try await importer.importRecipe(.photographedPage(image), in: context)

        guard case .saved = second else { Issue.record("expected saved"); return }
        #expect(try recipes(context).count == 2)
    }

    // MARK: failures

    @Test func nonWebpageLinkIsNotAWebpage() async throws {
        let network = Network()
        let context = try makeContainer(inMemory: true).mainContext
        await #expect(throws: RecipeImportError.notAWebpage) {
            try await make(network).importRecipe(.webpage(URL(string: "ftp://example.com/x")!), in: context)
        }
        #expect(network.fetched.isEmpty)
    }

    @Test func undownloadablePageIsBadResponse() async throws {
        let network = Network()  // no page registered: fetch throws
        let context = try makeContainer(inMemory: true).mainContext
        await #expect(throws: RecipeImportError.badResponse) {
            try await make(network).importRecipe(.webpage(pageURL), in: context)
        }
    }

    @Test func pageWithoutRecipeIsNoRecipeFound() async throws {
        let network = Network()
        network.pages[pageURL] = (200, Data("<html><body>Hi</body></html>".utf8))
        let context = try makeContainer(inMemory: true).mainContext
        await #expect(throws: RecipeImportError.noRecipeFound) {
            try await make(network).importRecipe(.webpage(pageURL), in: context)
        }
        #expect(try recipes(context).isEmpty)
    }

    @Test func photoWithoutTextIsNoTextFound() async throws {
        let network = Network()
        let context = try makeContainer(inMemory: true).mainContext
        await #expect(throws: RecipeImportError.noTextFound) {
            try await make(network, recognizerText: "  \n ").importRecipe(.photographedPage(Data([1])), in: context)
        }
        #expect(try recipes(context).isEmpty)
    }

    @Test func everyFailureHasAReadableMessage() {
        for error in [RecipeImportError.notAWebpage, .badResponse, .noRecipeFound, .noTextFound] {
            #expect(error.errorDescription?.isEmpty == false)
        }
    }
}

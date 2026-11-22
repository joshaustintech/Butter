import Foundation
import Testing
@testable import Butter

struct PhotoRecipeImporterTests {
    private struct FakeRecognizer: DocumentTextRecognizing {
        var text: String
        var error: (any Error)?
        func recognizeText(in imageData: Data) async throws -> String {
            if let error { throw error }
            return text
        }
    }

    private struct Boom: Error {}

    @Test func parsesRecognizedText() async throws {
        let importer = PhotoRecipeImporter(recognizer: FakeRecognizer(text: "Lemon Cake\nIngredients\n2 cups flour\n3 eggs"))
        let recipe = try await importer.importRecipe(from: Data([1]))
        #expect(recipe == RecipeTextParser.parse(text: "Lemon Cake\nIngredients\n2 cups flour\n3 eggs"))
        #expect(recipe.title == "Lemon Cake")
    }

    @Test func blankTextThrowsNoTextFound() async {
        let importer = PhotoRecipeImporter(recognizer: FakeRecognizer(text: " \n "))
        await #expect(throws: PhotoRecipeImportError.noTextFound) {
            try await importer.importRecipe(from: Data())
        }
    }

    @Test func recognizerErrorPropagates() async {
        let importer = PhotoRecipeImporter(recognizer: FakeRecognizer(text: "", error: Boom()))
        await #expect(throws: Boom.self) {
            try await importer.importRecipe(from: Data())
        }
    }
}

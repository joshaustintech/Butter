import Foundation
import SwiftData
import Testing
@testable import Butter

@MainActor
struct RecipeStoreTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        container = try ModelContainer(
            for: Recipe.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func aDraftWithOnlyATitleCommits() throws {
        var draft = RecipeDraft()
        draft.title = "Toast"
        let content = try #require(draft.content)

        try context.commit { context.insert(Recipe(content: content)) }

        let saved = try context.fetch(FetchDescriptor<Recipe>())
        #expect(saved.map(\.title) == ["Toast"])
        #expect(!context.hasChanges)
    }

    @Test func aDraftWithOnlyATitleSurvivesAFreshContext() throws {
        var draft = RecipeDraft()
        draft.title = "Toast"
        let content = try #require(draft.content)

        try context.commit { context.insert(Recipe(content: content)) }

        let other = ModelContext(container)
        #expect(try other.fetch(FetchDescriptor<Recipe>()).map(\.title) == ["Toast"])
    }

    @Test func aFailedSaveIsReportedWithItsReason() {
        let error = NSError(
            domain: NSCocoaErrorDomain, code: 134110,
            userInfo: [
                NSLocalizedDescriptionKey: "An error occurred during persistent store migration.",
                NSUnderlyingErrorKey: NSError(
                    domain: NSCocoaErrorDomain, code: 134110,
                    userInfo: ["reason": "Validation error missing attribute values on mandatory destination attribute"]
                ),
            ]
        )
        let failure = SaveFailure(title: "Couldn’t Save Recipe", error: error)
        #expect(failure.message.contains("persistent store migration"))
        #expect(failure.message.contains("missing attribute values"))
    }
}

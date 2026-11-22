import Foundation
import Testing
@testable import Butter

struct RecipeDraftTests {
    @Test func aNewDraftIsEmptyAndCannotBeSaved() {
        let draft = RecipeDraft()
        #expect(draft.title.isEmpty)
        #expect(draft.content == nil)
    }

    @Test(arguments: ["", "   ", "\n"])
    func aBlankTitleCannotBeSaved(_ title: String) {
        var draft = RecipeDraft()
        draft.title = title
        #expect(draft.content == nil)
    }

    @Test func aTitleAloneIsEnoughToSave() throws {
        var draft = RecipeDraft()
        draft.title = "  Honey Oat Scones "
        let content = try #require(draft.content)
        #expect(content.title.value == "Honey Oat Scones")
        #expect(content == RecipeContent(title: content.title))
    }

    @Test func blankLinesAndNotesAreDroppedAndTextIsTrimmed() throws {
        var draft = RecipeDraft()
        draft.title = "Focaccia"
        draft.ingredients = ["  flour ", "", "  ", "salt"].map { RecipeDraft.Line(text: $0) }
        draft.steps = ["", " Knead. "].map { RecipeDraft.Line(text: $0) }
        draft.reviewNotes = "   "
        let content = try #require(draft.content)
        #expect(content.ingredients.map(\.value) == ["flour", "salt"])
        #expect(content.steps.map(\.value) == ["Knead."])
        #expect(content.reviewNotes == nil)
    }

    @Test func roundTripsExistingContent() throws {
        var original = RecipeContent(title: try #require(NonBlankText("Rhubarb Galette")))
        original.photo = Data([1, 2, 3])
        original.prepMinutes = WholeNumber(30)
        original.bakeMinutes = WholeNumber(50)
        original.servings = WholeNumber(6)
        original.detailOrder = try #require(DetailOrder([.serves, .prep, .bake]))
        original.rating = Rating(5)
        original.ingredients = ["flour", "butter"].compactMap(NonBlankText.init)
        original.steps = ["Rub.", "Bake."].compactMap(NonBlankText.init)
        original.reviewNotes = NonBlankText("Tart and sweet.")

        let draft = RecipeDraft(original)
        #expect(draft.title == "Rhubarb Galette")
        #expect(draft.ingredients.map(\.text) == ["flour", "butter"])
        #expect(draft.content == original)
    }

    @Test func detailsAreEditableByKind() {
        var draft = RecipeDraft()
        draft[detail: .bake] = WholeNumber(45)
        #expect(draft.bakeMinutes?.value == 45)
        #expect(draft[detail: .bake]?.value == 45)
        draft[detail: .bake] = nil
        #expect(draft.bakeMinutes == nil)
    }

    @Test func addingLinesAppendsEmptyRowsWithFreshIdentity() {
        var draft = RecipeDraft()
        let first = draft.addIngredient()
        let second = draft.addIngredient()
        #expect(first != second)
        #expect(draft.ingredients.map(\.id) == [first, second])
        #expect(draft.ingredients.allSatisfy { $0.text.isEmpty })
        let step = draft.addStep()
        #expect(draft.steps.map(\.id) == [step])
    }

    @Test func removingAnIngredientLeavesTheOthersInOrder() {
        var draft = RecipeDraft()
        let ids = (0..<3).map { _ in draft.addIngredient() }
        draft.removeIngredient(id: ids[1])
        #expect(draft.ingredients.map(\.id) == [ids[0], ids[2]])
    }

    @Test func aDraftTracksWhetherItChanged() throws {
        let original = RecipeDraft(RecipeContent(title: try #require(NonBlankText("Scones"))))
        var edited = original
        #expect(edited == original)
        edited.rating = Rating(4)
        #expect(edited != original)
    }
}

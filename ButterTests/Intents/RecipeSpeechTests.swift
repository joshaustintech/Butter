import Foundation
import Testing
@testable import Butter

@MainActor
struct RecipeSpeechTests {
    @Test func findAnswerNamesMatches() {
        let recipes = [Recipe(title: "Lemon Chicken"), Recipe(title: "Pancakes")]
        #expect(RecipeSpeech.findAnswer(recipes: recipes, text: "chicken") == "You have 1 recipe: Lemon Chicken.")
    }

    @Test func findAnswerWhenNothingMatches() {
        #expect(RecipeSpeech.findAnswer(recipes: [], text: "soup").hasPrefix("I couldn't find"))
    }

    @Test func recentAnswerUsesRange() {
        let now = Date.now
        let old = Recipe(title: "Old", savedDate: now.addingTimeInterval(-60 * 86_400))
        let new = Recipe(title: "New", savedDate: now.addingTimeInterval(-3_600))
        let answer = RecipeSpeech.recentAnswer(recipes: [old, new], range: .lastMonth, now: now)
        #expect(answer == "You have 1 recipe: New.")
    }

    @Test func enumMapsToRange() {
        #expect(SavedRangeOption.lastWeek.savedRange == .lastWeek)
    }
}

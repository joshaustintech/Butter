import Foundation
import Testing
@testable import Butter

@MainActor
struct RecipeAnswersTests {
    let cal = Calendar(identifier: .gregorian)
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let day: TimeInterval = 86_400
    let nothing = "I couldn't find any recipes. Try another search."

    func titled(_ titles: [String]) -> [Recipe] { titles.map { Recipe(title: $0) } }

    func answer(_ question: RecipeQuestion, _ recipes: [Recipe]) -> String {
        RecipeAnswers.answer(to: question, from: recipes, now: now, calendar: cal)
    }

    @Test func noMatchesSaysNothingFound() {
        #expect(answer(.find("soup"), []) == nothing)
    }

    @Test func blankSearchFindsNothing() {
        #expect(answer(.find("  "), titled(["A"])) == nothing)
    }

    @Test func oneMatchSaysOneRecipe() {
        let recipes = titled(["Lemon Chicken", "Pancakes"])
        #expect(answer(.find("chicken"), recipes) == "You have 1 recipe: Lemon Chicken.")
    }

    @Test func twoToFiveListAllTitles() {
        let recipes = titled(["Pie A", "Pie B", "Pie C"])
        #expect(answer(.find("pie"), recipes) == "You have 3 recipes: Pie A, Pie B and Pie C.")
        #expect(answer(.find("pie"), Array(recipes.prefix(2))) == "You have 2 recipes: Pie A and Pie B.")
        let five = titled(["P1", "P2", "P3", "P4", "P5"])
        #expect(answer(.find("p"), five) == "You have 5 recipes: P1, P2, P3, P4 and P5.")
    }

    @Test func moreThanFiveReadsFiveAndCountsTheRest() {
        let seven = titled(["P1", "P2", "P3", "P4", "P5", "P6", "P7"])
        #expect(answer(.find("p"), seven) == "You have 7 recipes: P1, P2, P3, P4, P5, and 2 more.")
    }

    @Test func untitledRecipeIsReadAsUntitled() {
        let recipes = [Recipe(title: "", ingredients: ["flour"])]
        #expect(answer(.find("flour"), recipes) == "You have 1 recipe: Untitled.")
    }

    @Test func searchIgnoresCaseAndAccentsAndRanksTitlesFirst() {
        let stew = Recipe(title: "Beef Stew", ingredients: ["2 carrots"])
        let cake = Recipe(title: "Crème brûlée", ingredients: ["cream"])
        let soup = Recipe(title: "Carrot Soup", ingredients: ["stock"])
        #expect(answer(.find("CARROT"), [stew, cake, soup]) == "You have 2 recipes: Carrot Soup and Beef Stew.")
        #expect(answer(.find("creme"), [cake]) == "You have 1 recipe: Crème brûlée.")
    }

    @Test func savedRangesFilterAndSortNewestFirst() {
        let a = Recipe(title: "A", savedDate: now.addingTimeInterval(-3_600))
        let b = Recipe(title: "B", savedDate: now.addingTimeInterval(-3 * day))
        let c = Recipe(title: "C", savedDate: now.addingTimeInterval(-20 * day))
        let d = Recipe(title: "D", savedDate: now.addingTimeInterval(-90 * day))
        let all = [d, c, b, a]
        #expect(answer(.saved(.lastWeek), all) == "You have 2 recipes: A and B.")
        #expect(answer(.saved(.lastMonth), all) == "You have 3 recipes: A, B and C.")
        #expect(answer(.saved(.today), all) == "You have 1 recipe: A.")
        #expect(answer(.saved(.today), [d]) == nothing)
    }
}

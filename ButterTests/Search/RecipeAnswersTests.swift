import Foundation
import Testing
@testable import Butter

@MainActor
struct RecipeAnswersTests {
    let cal: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
    /// 2027-01-15 08:00 UTC.
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

    func saved(_ title: String, at date: Date) -> Recipe { Recipe(title: title, savedDate: date) }

    @Test func todayStartsAtMidnightOfNow() {
        let midnight = cal.startOfDay(for: now)
        let atMidnight = saved("A", at: midnight)
        let justBefore = saved("B", at: midnight.addingTimeInterval(-1))
        let future = saved("C", at: now.addingTimeInterval(1))
        #expect(answer(.saved(.today), [justBefore, future, atMidnight]) == "You have 1 recipe: A.")
        #expect(answer(.saved(.today), [justBefore]) == nothing)
    }

    @Test func lastWeekStartsSevenDaysBeforeNow() {
        let start = cal.date(byAdding: .day, value: -7, to: now)!
        let atStart = saved("A", at: start)
        let newer = saved("B", at: now.addingTimeInterval(-3_600))
        let justBefore = saved("C", at: start.addingTimeInterval(-1))
        #expect(answer(.saved(.lastWeek), [justBefore, atStart, newer]) == "You have 2 recipes: B and A.")
    }

    @Test func lastMonthStartsOneMonthBeforeNow() {
        let start = cal.date(byAdding: .month, value: -1, to: now)!
        let atStart = saved("A", at: start)
        let newer = saved("B", at: now.addingTimeInterval(-3 * day))
        let justBefore = saved("C", at: start.addingTimeInterval(-1))
        #expect(answer(.saved(.lastMonth), [justBefore, atStart, newer]) == "You have 2 recipes: B and A.")
    }
}

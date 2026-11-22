import Foundation
import Testing
@testable import Butter

struct RecipeContentTests {
    private func content(
        prep: Int? = nil,
        bake: Int? = nil,
        servings: Int? = nil,
        rating: Double? = nil,
        order: DetailOrder = .standard
    ) throws -> RecipeContent {
        var content = RecipeContent(title: try #require(NonBlankText("Rhubarb Galette")))
        content.prepMinutes = prep.flatMap(WholeNumber.init)
        content.bakeMinutes = bake.flatMap(WholeNumber.init)
        content.servings = servings.flatMap(WholeNumber.init)
        content.rating = rating.flatMap(Rating.init)
        content.detailOrder = order
        return content
    }

    @Test func everythingButTheTitleStartsEmpty() throws {
        let content = try content()
        #expect(content.photo == nil)
        #expect(content.prepMinutes == nil && content.bakeMinutes == nil && content.servings == nil)
        #expect(content.detailOrder == .standard)
        #expect(content.rating == nil)
        #expect(content.ingredients.isEmpty && content.steps.isEmpty)
        #expect(content.reviewNotes == nil)
    }

    @Test func totalTimeAddsWhicheverTimesAreSet() throws {
        #expect(try content().totalMinutes == nil)
        #expect(try content(prep: 30).totalMinutes == 30)
        #expect(try content(bake: 50).totalMinutes == 50)
        #expect(try content(prep: 30, bake: 50).totalMinutes == 80)
        #expect(try content(servings: 6).totalMinutes == nil)
    }

    @Test func summaryShowsRatingAndTotalTime() throws {
        let summary = try content(prep: 30, bake: 50, rating: 4.5).summary
        #expect(summary == .details(rating: "4.5", time: "1 hr 20 min"))
    }

    @Test func summaryShowsWhicheverPartExists() throws {
        #expect(try content(rating: 5).summary == .details(rating: "5.0", time: nil))
        #expect(try content(prep: 10).summary == .details(rating: nil, time: "10 min"))
    }

    @Test func summaryWithNeitherRatingNorTimeSaysNoDetailsYet() throws {
        let summary = try content(servings: 4).summary
        #expect(summary == .noDetails)
        #expect(summary.noDetailsText == "No details yet")
    }

    @Test func statsOnlyIncludeTilesWithAValueInTheSavedOrder() throws {
        let order = try #require(DetailOrder([.serves, .bake, .prep]))
        let stats = try content(prep: 10, servings: 2, order: order).stats
        #expect(stats == [
            RecipeStat(kind: .serves, text: "2"),
            RecipeStat(kind: .prep, text: "10 min"),
        ])
    }

    @Test func statsFormatTimesAndServings() throws {
        let stats = try content(prep: 30, bake: 80, servings: 6).stats
        #expect(stats.map(\.text) == ["30 min", "1 hr 20 min", "6"])
    }

    @Test func noStatsWhenNoDetailsAreSet() throws {
        #expect(try content(rating: 3).stats.isEmpty)
    }

    @Test func detailValuesAreReadableByKind() throws {
        let content = try content(prep: 1, bake: 2, servings: 3)
        #expect(DetailKind.allCases.map { content.value(for: $0)?.value } == [1, 2, 3])
    }
}

struct AddedDateTests {
    @Test func formatsAsAbbreviatedMonthAndDay() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Chicago"))
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 18, hour: 9)))
        let text = AddedDate.text(
            for: date,
            locale: Locale(identifier: "en_US"),
            timeZone: calendar.timeZone
        )
        #expect(text == "Added Nov 18")
    }
}

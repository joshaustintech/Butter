import Testing
@testable import Butter

struct RatingTests {
    @Test(arguments: 1...10)
    func acceptsHalfStarCountsFromOneToTen(_ halfStars: Int) {
        #expect(Rating(halfStars: halfStars)?.value == Double(halfStars) / 2)
    }

    @Test(arguments: [0, 11, -2])
    func rejectsHalfStarCountsOutsideTheScale(_ halfStars: Int) {
        #expect(Rating(halfStars: halfStars) == nil)
    }

    @Test(arguments: [0.5, 1.0, 4.5, 5.0])
    func acceptsHalfStepValues(_ value: Double) {
        #expect(Rating(value)?.value == value)
    }

    @Test(arguments: [0.0, 4.3, 5.5, -1.0, .nan])
    func rejectsValuesThatAreNotHalfSteps(_ value: Double) {
        #expect(Rating(value) == nil)
    }

    @Test func formatsWithOneDecimal() {
        #expect(Rating(4.5)?.formatted == "4.5")
        #expect(Rating(5)?.formatted == "5.0")
    }

    @Test func describesItselfOutOfFive() {
        #expect(Rating.outOfFive(Rating(4.5)) == "4.5 of 5")
        #expect(Rating.outOfFive(nil) == "Not rated")
    }

    @Test func tappingTheLeftHalfOfAStarPicksTheHalfStep() {
        #expect(Rating(star: 3, half: .leading)?.value == 2.5)
        #expect(Rating(star: 3, half: .trailing)?.value == 3)
        #expect(Rating(star: 1, half: .leading)?.value == 0.5)
        #expect(Rating(star: 6, half: .leading) == nil)
    }

    @Test func raisingStartsAtHalfAStarAndStopsAtFive() {
        #expect(Rating.raised(nil).value == 0.5)
        #expect(Rating.raised(Rating(4)).value == 4.5)
        #expect(Rating.raised(.maximum) == .maximum)
    }

    @Test func loweringBelowHalfAStarClearsTheRating() {
        #expect(Rating(4.5)?.lowered()?.value == 4)
        #expect(Rating(0.5)?.lowered() == nil)
    }

    @Test func eachStarIsFullHalfOrEmpty() throws {
        let rating = try #require(Rating(3.5))
        #expect((1...5).map(rating.fill(ofStar:)) == [.full, .full, .full, .half, .empty])
    }

    @Test func starFillsUseTheHandoffSymbols() {
        #expect(StarFill.full.symbolName == "star.fill")
        #expect(StarFill.half.symbolName == "star.leadinghalf.filled")
        #expect(StarFill.empty.symbolName == "star")
    }
}

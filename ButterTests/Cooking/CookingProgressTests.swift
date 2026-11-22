import Testing
@testable import Butter

struct CookingProgressTests {
    @Test func rejectsEmptyRecipes() {
        #expect(CookingProgress(stepCount: 0) == nil)
        #expect(CookingProgress(stepCount: -1) == nil)
    }

    @Test func startsOnFirstStep() throws {
        let progress = try #require(CookingProgress(stepCount: 5))
        #expect(progress.index == 0)
        #expect(progress.isFirst)
        #expect(!progress.isLast)
        #expect(progress.positionDescription == "Step 1 of 5")
    }

    @Test func advanceAndGoBackMoveOneStep() throws {
        var progress = try #require(CookingProgress(stepCount: 5))
        #expect(progress.advance() == .moved)
        #expect(progress.index == 1)
        #expect(progress.positionDescription == "Step 2 of 5")
        #expect(progress.goBack() == .moved)
        #expect(progress.index == 0)
        #expect(progress.isFirst)
    }

    @Test func goBackClampsAtFirstStep() throws {
        var progress = try #require(CookingProgress(stepCount: 3))
        #expect(progress.goBack() == .unchanged)
        #expect(progress.index == 0)
        #expect(progress.isFirst)
    }

    @Test func advanceToLastStepThenFinishes() throws {
        var progress = try #require(CookingProgress(stepCount: 3))
        #expect(progress.advance() == .moved)
        #expect(progress.advance() == .moved)
        #expect(progress.index == 2)
        #expect(progress.isLast)
        #expect(!progress.isFirst)
        #expect(progress.positionDescription == "Step 3 of 3")

        #expect(progress.advance() == .finished)
        #expect(progress.index == 2)
        #expect(progress.isLast)
    }

    @Test func singleStepIsFirstAndLast() throws {
        var progress = try #require(CookingProgress(stepCount: 1))
        #expect(progress.isFirst)
        #expect(progress.isLast)
        #expect(progress.positionDescription == "Step 1 of 1")
        #expect(progress.advance() == .finished)
        #expect(progress.goBack() == .unchanged)
        #expect(progress.index == 0)
    }
}

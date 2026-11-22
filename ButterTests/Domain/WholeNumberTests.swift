import Testing
@testable import Butter

struct WholeNumberTests {
    @Test(arguments: [1, 6, 9999])
    func acceptsPositiveNumbersUpToFourDigits(_ value: Int) {
        #expect(WholeNumber(value)?.value == value)
    }

    @Test(arguments: [-1, 0, 10_000])
    func rejectsZeroNegativeAndFiveDigitNumbers(_ value: Int) {
        #expect(WholeNumber(value) == nil)
    }

    @Test(arguments: [
        ("12", "12"),
        ("0012", "12"),
        ("000", ""),
        ("a1b2c3", "123"),
        ("1.5", "15"),
        ("-4", "4"),
        ("12345", "1234"),
        ("٣", ""),
        ("", ""),
    ])
    func sanitizesTypedText(typed: String, expected: String) {
        #expect(WholeNumber.sanitized(typed) == expected)
    }

    @Test func parsesCleanDigits() {
        #expect(WholeNumber(digits: "42")?.value == 42)
    }

    @Test(arguments: ["", "042", "4 2", "12345", "x"])
    func refusesDigitsThatAreNotAlreadyClean(_ digits: String) {
        #expect(WholeNumber(digits: digits) == nil)
    }

    @Test func describesItselfAsPlainDigits() {
        #expect(WholeNumber(1200)?.description == "1200")
    }
}

struct MinutesFormatTests {
    @Test(arguments: [
        (10, "10 min"),
        (59, "59 min"),
        (60, "1 hr"),
        (80, "1 hr 20 min"),
        (180, "3 hr"),
        (605, "10 hr 5 min"),
    ])
    func formatsMinutesTheWayTheDesignShowsThem(minutes: Int, text: String) {
        #expect(MinutesFormat.string(minutes) == text)
    }
}

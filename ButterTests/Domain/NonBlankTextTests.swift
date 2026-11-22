import Testing
@testable import Butter

struct NonBlankTextTests {
    @Test(arguments: ["", " ", "\n\t  "])
    func rejectsBlankText(_ raw: String) {
        #expect(NonBlankText(raw) == nil)
    }

    @Test func trimsSurroundingWhitespaceButKeepsInnerSpacing() {
        #expect(NonBlankText("  Rhubarb  Galette \n")?.value == "Rhubarb  Galette")
    }
}

struct MonogramTests {
    @Test(arguments: [
        ("Rhubarb Galette", "R"),
        ("lemon ricotta pancakes", "L"),
        ("½ cup lemon curd", "C"),
        ("123 Bean Soup", "B"),
        ("  éclairs", "É"),
    ])
    func usesTheFirstLetterUppercased(title: String, letter: String) {
        #expect(Monogram.letter(in: title) == letter)
    }

    @Test func fallsBackToTheFirstCharacterWhenThereIsNoLetter() {
        #expect(Monogram.letter(in: " 42 ") == "4")
    }

    @Test func blankTitlesHaveNoMonogram() {
        #expect(Monogram.letter(in: "   ") == nil)
    }
}

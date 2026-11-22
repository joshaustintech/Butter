import Testing
@testable import Butter

struct CookingCommandTests {
    @Test func recognizesCommandPhrases() {
        #expect(CookingCommand.parse(transcript: "next") == .next)
        #expect(CookingCommand.parse(transcript: "next step") == .next)
        #expect(CookingCommand.parse(transcript: "continue") == .next)
        #expect(CookingCommand.parse(transcript: "back") == .back)
        #expect(CookingCommand.parse(transcript: "previous") == .back)
        #expect(CookingCommand.parse(transcript: "go back") == .back)
        #expect(CookingCommand.parse(transcript: "repeat") == .repeatStep)
        #expect(CookingCommand.parse(transcript: "again") == .repeatStep)
        #expect(CookingCommand.parse(transcript: "say that again") == .repeatStep)
        #expect(CookingCommand.parse(transcript: "stop") == .stop)
        #expect(CookingCommand.parse(transcript: "done") == .stop)
        #expect(CookingCommand.parse(transcript: "finish") == .stop)
        #expect(CookingCommand.parse(transcript: "quit") == .stop)
    }

    @Test func ignoresCaseAndPunctuation() {
        #expect(CookingCommand.parse(transcript: "Next!") == .next)
        #expect(CookingCommand.parse(transcript: "NEXT STEP.") == .next)
        #expect(CookingCommand.parse(transcript: "  Go   back,  ") == .back)
        #expect(CookingCommand.parse(transcript: "Say that again?") == .repeatStep)
        #expect(CookingCommand.parse(transcript: "Stop!!") == .stop)
    }

    @Test func ignoresFillerWords() {
        #expect(CookingCommand.parse(transcript: "Okay, next") == .next)
        #expect(CookingCommand.parse(transcript: "next please") == .next)
        #expect(CookingCommand.parse(transcript: "Butter, go back") == .back)
        #expect(CookingCommand.parse(transcript: "okay butter stop please") == .stop)
    }

    @Test func returnsNilForUnrelatedSpeech() {
        #expect(CookingCommand.parse(transcript: "") == nil)
        #expect(CookingCommand.parse(transcript: "   ") == nil)
        #expect(CookingCommand.parse(transcript: "the onions smell great") == nil)
        #expect(CookingCommand.parse(transcript: "butter") == nil)
        #expect(CookingCommand.parse(transcript: "please") == nil)
    }

    @Test func returnsNilForLongerSentencesContainingKeywords() {
        #expect(CookingCommand.parse(transcript: "next to the stove") == nil)
        #expect(CookingCommand.parse(transcript: "I'm done with the onions") == nil)
        #expect(CookingCommand.parse(transcript: "stop the timer and start again") == nil)
        #expect(CookingCommand.parse(transcript: "back of the pan") == nil)
        #expect(CookingCommand.parse(transcript: "what is the next step after this") == nil)
    }
}

import Foundation

/// A hands-free instruction spoken during a Cooking session. Pure: it knows
/// nothing about audio or UI, only how a transcript maps to a command.
nonisolated enum CookingCommand: Equatable, Sendable {
    case next
    case back
    case repeatStep
    case stop

    /// Maps a transcript to a command, or `nil` when the speech is unrelated.
    /// Matching ignores case, punctuation and filler words, and requires the
    /// whole utterance to be a command phrase, so "next to the stove" is `nil`.
    static func parse(transcript: String) -> CookingCommand? {
        let fillers: Set<String> = ["okay", "ok", "please", "butter"]
        let words = transcript
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && !fillers.contains($0) }

        switch words {
        case ["next"], ["next", "step"], ["continue"]:
            return .next
        case ["back"], ["previous"], ["previous", "step"], ["go", "back"]:
            return .back
        case ["repeat"], ["again"], ["say", "that", "again"]:
            return .repeatStep
        case ["stop"], ["done"], ["finish"], ["quit"]:
            return .stop
        default:
            return nil
        }
    }
}

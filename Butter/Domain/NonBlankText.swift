import Foundation

/// Text that is guaranteed to contain something other than whitespace,
/// stored trimmed. Used for titles, ingredients, steps and review notes,
/// so a recipe can never hold an empty line.
struct NonBlankText: Hashable, Sendable {
    let value: String

    init?(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        value = trimmed
    }
}

/// The single letter that stands in for a recipe without a photo.
enum Monogram {
    /// The first letter of `title`, uppercased; the first visible character
    /// if the title has no letters; `nil` if the title is blank.
    static func letter(in title: String) -> String? {
        let visible = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let character = visible.first(where: \.isLetter) ?? visible.first else { return nil }
        return String(character).uppercased()
    }
}

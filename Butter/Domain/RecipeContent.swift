import Foundation

/// Everything a recipe says, as validated values. Only the title is required;
/// every other field is either set to something valid or absent.
struct RecipeContent: Equatable, Sendable {
    var title: NonBlankText
    var photo: Data?
    var prepMinutes: WholeNumber?
    var bakeMinutes: WholeNumber?
    var servings: WholeNumber?
    var detailOrder: DetailOrder = .standard
    var rating: Rating?
    var ingredients: [NonBlankText] = []
    var steps: [NonBlankText] = []
    var reviewNotes: NonBlankText?

    init(title: NonBlankText) {
        self.title = title
    }

    func value(for kind: DetailKind) -> WholeNumber? {
        switch kind {
        case .prep: prepMinutes
        case .bake: bakeMinutes
        case .serves: servings
        }
    }

    /// Prep plus bake, counting whichever are set; `nil` when neither is.
    var totalMinutes: Int? {
        let times = [prepMinutes, bakeMinutes].compactMap { $0?.value }
        return times.isEmpty ? nil : times.reduce(0, +)
    }

    /// The list row's meta line.
    var summary: RecipeSummary {
        let rating = rating?.formatted
        let time = totalMinutes.map(MinutesFormat.string)
        return rating == nil && time == nil ? .noDetails : .details(rating: rating, time: time)
    }

    /// The detail screen's tiles: only details with a value, in the saved order.
    var stats: [RecipeStat] {
        detailOrder.kinds.compactMap { kind in
            value(for: kind).map { RecipeStat(kind: kind, text: kind.text(for: $0)) }
        }
    }
}

/// What a list row says beneath the title.
enum RecipeSummary: Equatable, Sendable {
    /// At least one of the two is present.
    case details(rating: String?, time: String?)
    case noDetails

    var noDetailsText: String { "No details yet" }
}

struct RecipeStat: Equatable, Identifiable, Sendable {
    let kind: DetailKind
    let text: String

    var id: DetailKind { kind }
}

enum AddedDate {
    /// `Added Nov 18`.
    static func text(for date: Date, locale: Locale = .current, timeZone: TimeZone = .current) -> String {
        var style = Date.FormatStyle(locale: locale, timeZone: timeZone).month(.abbreviated).day()
        style.calendar = Calendar(identifier: .gregorian)
        return "Added \(date.formatted(style))"
    }
}

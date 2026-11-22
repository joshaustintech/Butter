/// A rating from 0.5 to 5.0 in half-star steps, stored as a count of half
/// stars so no other value can exist. "Unrated" is `Rating?.none`.
struct Rating: Hashable, Sendable {
    static let maximum = Rating(uncheckedHalfStars: 10)
    private static let halfStarRange = 1...10

    let halfStars: Int

    init?(halfStars: Int) {
        guard Self.halfStarRange.contains(halfStars) else { return nil }
        self.halfStars = halfStars
    }

    init?(_ value: Double) {
        let doubled = value * 2
        guard doubled.isFinite, doubled == doubled.rounded() else { return nil }
        self.init(halfStars: Int(doubled))
    }

    /// The rating chosen by tapping one half of star `star` (1...5).
    init?(star: Int, half: StarHalf) {
        guard (1...5).contains(star) else { return nil }
        self.init(halfStars: star * 2 - (half == .leading ? 1 : 0))
    }

    private init(uncheckedHalfStars: Int) {
        halfStars = uncheckedHalfStars
    }

    var value: Double { Double(halfStars) / 2 }

    /// One decimal place: `4.5`, `5.0`.
    var formatted: String { value.formatted(.number.precision(.fractionLength(1))) }

    /// `4.5 of 5`, or `Not rated`.
    static func outOfFive(_ rating: Rating?) -> String {
        rating.map { "\($0.formatted) of 5" } ?? "Not rated"
    }

    /// Half a star more, starting from half a star when unrated and stopping at five.
    static func raised(_ rating: Rating?) -> Rating {
        guard let rating else { return Rating(uncheckedHalfStars: 1) }
        return Rating(halfStars: rating.halfStars + 1) ?? .maximum
    }

    /// Half a star less; lowering half a star clears the rating.
    func lowered() -> Rating? {
        Rating(halfStars: halfStars - 1)
    }

    func fill(ofStar star: Int) -> StarFill {
        switch halfStars - (star - 1) * 2 {
        case ...0: .empty
        case 1: .half
        default: .full
        }
    }
}

enum StarHalf: Sendable {
    case leading, trailing
}

enum StarFill: Sendable {
    case empty, half, full

    var symbolName: String {
        switch self {
        case .empty: "star"
        case .half: "star.leadinghalf.filled"
        case .full: "star.fill"
        }
    }
}

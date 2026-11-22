/// A positive whole number of at most four digits: the only values allowed
/// for prep time, bake time and servings.
struct WholeNumber: Hashable, Sendable, CustomStringConvertible {
    static let range = 1...9999
    private static let maximumDigits = 4

    let value: Int

    init?(_ value: Int) {
        guard Self.range.contains(value) else { return nil }
        self.value = value
    }

    /// Parses text that is already clean: ASCII digits only, no leading zero.
    init?(digits: String) {
        guard !digits.isEmpty, Self.sanitized(digits) == digits, let value = Int(digits) else { return nil }
        self.init(value)
    }

    var description: String { String(value) }

    /// Reduces whatever was typed to clean digits: ASCII digits only,
    /// no leading zeros, at most four digits. Blank means "not set".
    static func sanitized(_ typed: String) -> String {
        let digits = typed.filter { $0.isASCII && $0.isNumber }
        return String(digits.drop { $0 == "0" }.prefix(maximumDigits))
    }
}

/// Formats a number of minutes as the design writes it:
/// `10 min`, `1 hr 20 min`, `3 hr`.
enum MinutesFormat {
    static func string(_ minutes: Int) -> String {
        let hours = minutes / 60, remainder = minutes % 60
        switch (hours, remainder) {
        case (0, _): return "\(minutes) min"
        case (_, 0): return "\(hours) hr"
        default: return "\(hours) hr \(remainder) min"
        }
    }
}

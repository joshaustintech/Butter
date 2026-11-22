/// Position within a Cooking session's Steps. Pure: `index` is zero-based and
/// is clamped to the first and last Step.
nonisolated struct CookingProgress: Equatable, Sendable {
    /// The outcome of moving through the Steps.
    enum Movement: Equatable, Sendable {
        /// The index changed.
        case moved
        /// `advance()` was called on the last Step, so the session is finishing.
        case finished
        /// `goBack()` was called on the first Step, so nothing changed.
        case unchanged
    }

    let stepCount: Int
    private(set) var index: Int = 0

    /// Returns `nil` when there are no Steps to walk through.
    init?(stepCount: Int) {
        guard stepCount >= 1 else { return nil }
        self.stepCount = stepCount
    }

    var isFirst: Bool { index == 0 }
    var isLast: Bool { index == stepCount - 1 }

    /// Spoken position, one-based for the cook, e.g. "Step 2 of 5".
    var positionDescription: String {
        "Step \(index + 1) of \(stepCount)"
    }

    /// Moves to the next Step. On the last Step the index stays put and the
    /// result is `.finished`.
    mutating func advance() -> Movement {
        guard !isLast else { return .finished }
        index += 1
        return .moved
    }

    /// Moves to the previous Step. On the first Step the index stays put and
    /// the result is `.unchanged`.
    @discardableResult
    mutating func goBack() -> Movement {
        guard !isFirst else { return .unchanged }
        index -= 1
        return .moved
    }
}

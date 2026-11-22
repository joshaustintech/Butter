/// The three optional numeric details a recipe can have.
enum DetailKind: String, CaseIterable, Identifiable, Sendable {
    case prep, bake, serves

    var id: Self { self }

    /// Label on the detail screen's stat tile.
    var tileLabel: String {
        switch self {
        case .prep: "Prep"
        case .bake: "Bake"
        case .serves: "Serves"
        }
    }

    /// Label on the editor's Details row.
    var fieldLabel: String {
        switch self {
        case .prep: "Prep time"
        case .bake: "Bake time"
        case .serves: "Serves"
        }
    }

    /// Suffix shown after the editor's number field.
    var unit: String? {
        switch self {
        case .prep, .bake: "min"
        case .serves: nil
        }
    }

    /// The value as the editor shows it while reordering: `1 hr 20 min`, `6`, `Not set`.
    func text(for value: WholeNumber?) -> String {
        guard let value else { return "Not set" }
        return unit == nil ? value.description : MinutesFormat.string(value.value)
    }

    var tint: TileTint {
        switch self {
        case .prep: .sage
        case .bake: .butter
        case .serves: .rose
        }
    }
}

/// The order of the Details rows and stat tiles. Always contains every
/// `DetailKind` exactly once.
struct DetailOrder: Hashable, Sendable {
    static let standard = DetailOrder(unchecked: DetailKind.allCases)

    private(set) var kinds: [DetailKind]

    init?(_ kinds: [DetailKind]) {
        guard kinds.count == DetailKind.allCases.count, Set(kinds) == Set(DetailKind.allCases) else { return nil }
        self.kinds = kinds
    }

    /// Reads the persisted form, falling back to the standard order.
    init(storage: String) {
        let kinds = storage.split(separator: ",").compactMap { DetailKind(rawValue: String($0)) }
        self = DetailOrder(kinds) ?? .standard
    }

    private init(unchecked kinds: [DetailKind]) {
        self.kinds = kinds
    }

    var storage: String { kinds.map(\.rawValue).joined(separator: ",") }

    mutating func move(_ kind: DetailKind, to index: Int) {
        kinds.move(id: kind, to: index)
    }
}

extension Array where Element: Identifiable {
    /// Moves the element with `id` so it ends up at `index` (clamped).
    mutating func move(id: Element.ID, to index: Int) {
        guard let from = firstIndex(where: { $0.id == id }) else { return }
        let element = remove(at: from)
        insert(element, at: Swift.min(Swift.max(index, 0), count))
    }
}

enum Reordering {
    /// Where the row at `index` belongs while its handle is held at vertical
    /// position `y`. It takes a neighbour's place once the finger passes that
    /// neighbour's midpoint, so rows of different heights don't flip back and forth.
    static func destination(ofRow index: Int, draggedTo y: Double, rows: [ClosedRange<Double>]) -> Int {
        guard rows.indices.contains(index) else { return index }
        func midpoint(_ row: Int) -> Double { (rows[row].lowerBound + rows[row].upperBound) / 2 }
        var destination = index
        while destination > 0, y < midpoint(destination - 1) { destination -= 1 }
        while destination < rows.count - 1, y > midpoint(destination + 1) { destination += 1 }
        return destination
    }
}

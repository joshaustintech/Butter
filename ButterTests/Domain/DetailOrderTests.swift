import Testing
@testable import Butter

struct DetailOrderTests {
    @Test func defaultsToPrepBakeServes() {
        #expect(DetailOrder.standard.kinds == [.prep, .bake, .serves])
    }

    @Test func acceptsAnyPermutation() {
        #expect(DetailOrder([.serves, .prep, .bake])?.kinds == [.serves, .prep, .bake])
    }

    @Test(arguments: [
        [DetailKind](),
        [.prep, .bake],
        [.prep, .prep, .serves],
        [.prep, .bake, .serves, .bake],
    ])
    func rejectsAnythingThatIsNotAPermutation(_ kinds: [DetailKind]) {
        #expect(DetailOrder(kinds) == nil)
    }

    @Test func movingKeepsEveryKindExactlyOnce() {
        var order = DetailOrder.standard
        order.move(.serves, to: 0)
        #expect(order.kinds == [.serves, .prep, .bake])
        order.move(.serves, to: 2)
        #expect(order.kinds == [.prep, .bake, .serves])
        order.move(.prep, to: 99)
        #expect(order.kinds == [.bake, .serves, .prep])
    }

    @Test func roundTripsThroughStorage() throws {
        let order = try #require(DetailOrder([.bake, .serves, .prep]))
        #expect(DetailOrder(storage: order.storage) == order)
    }

    @Test(arguments: ["", "bake,bake,prep", "prep,bake", "nonsense"])
    func unreadableStorageFallsBackToTheStandardOrder(_ storage: String) {
        #expect(DetailOrder(storage: storage) == .standard)
    }

    @Test(arguments: [
        (DetailKind.prep, 80, "1 hr 20 min"),
        (.bake, 50, "50 min"),
        (.serves, 6, "6"),
    ])
    func displaysValuesInTheirUnits(kind: DetailKind, value: Int, text: String) {
        #expect(kind.text(for: WholeNumber(value)) == text)
    }

    @Test func displaysUnsetValuesAsNotSet() {
        #expect(DetailKind.allCases.map { $0.text(for: nil) } == ["Not set", "Not set", "Not set"])
    }

    @Test func kindsHaveTheHandoffLabels() {
        #expect(DetailKind.allCases.map(\.tileLabel) == ["Prep", "Bake", "Serves"])
        #expect(DetailKind.allCases.map(\.fieldLabel) == ["Prep time", "Bake time", "Serves"])
        #expect(DetailKind.allCases.map(\.unit) == ["min", "min", nil])
    }
}

struct ReorderingTests {
    struct Item: Identifiable, Equatable { let id: Int }

    @Test func movesAnElementByIdentity() {
        var items = [1, 2, 3, 4].map(Item.init)
        items.move(id: 1, to: 2)
        #expect(items.map(\.id) == [2, 3, 1, 4])
        items.move(id: 4, to: 0)
        #expect(items.map(\.id) == [4, 2, 3, 1])
    }

    @Test func ignoresUnknownIdentitiesAndClampsTheDestination() {
        var items = [1, 2, 3].map(Item.init)
        items.move(id: 9, to: 0)
        #expect(items.map(\.id) == [1, 2, 3])
        items.move(id: 1, to: 40)
        #expect(items.map(\.id) == [2, 3, 1])
        items.move(id: 1, to: -3)
        #expect(items.map(\.id) == [1, 2, 3])
    }

    @Test func dragsPastANeighboursMidpointToTakeItsPlace() {
        let rows: [ClosedRange<Double>] = [0...52, 52...104, 104...156]
        #expect(Reordering.destination(ofRow: 0, draggedTo: 70, rows: rows) == 0)
        #expect(Reordering.destination(ofRow: 0, draggedTo: 80, rows: rows) == 1)
        #expect(Reordering.destination(ofRow: 0, draggedTo: 131, rows: rows) == 2)
        #expect(Reordering.destination(ofRow: 2, draggedTo: 20, rows: rows) == 0)
    }

    @Test func dragsPastTheEndsLandOnTheFirstOrLastRow() {
        let rows: [ClosedRange<Double>] = [0...52, 52...104]
        #expect(Reordering.destination(ofRow: 1, draggedTo: -30, rows: rows) == 0)
        #expect(Reordering.destination(ofRow: 0, draggedTo: 400, rows: rows) == 1)
    }

    @Test func aShortRowDraggedOverATallOneDoesNotFlipBack() {
        // Short row B dragged up over tall row A swaps once...
        let before: [ClosedRange<Double>] = [0...100, 100...150]
        #expect(Reordering.destination(ofRow: 1, draggedTo: 40, rows: before) == 0)
        // ...and once laid out again, the same finger position keeps it there.
        let after: [ClosedRange<Double>] = [0...50, 50...150]
        #expect(Reordering.destination(ofRow: 0, draggedTo: 40, rows: after) == 0)
    }

    @Test func unknownRowsStayPut() {
        #expect(Reordering.destination(ofRow: 3, draggedTo: 10, rows: [0...52]) == 3)
    }
}

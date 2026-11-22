import SwiftUI

private let reorderSpace = "ReorderableRows"

/// Card rows separated by rules. While reordering, each row gets a trailing
/// grip; dragging the grip moves the row, which is tinted `fill` while held.
struct ReorderableRows<Item: Identifiable, Row: View>: View {
    let items: [Item]
    let isReordering: Bool
    /// What VoiceOver calls the row's handle, e.g. "Prep time".
    let name: (Item) -> String
    let move: (Item.ID, Int) -> Void
    @ViewBuilder let row: (Item) -> Row

    @State private var rowFrames: [Item.ID: ClosedRange<Double>] = [:]
    @State private var held: Item.ID?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 { CardDivider() }
                HStack(spacing: 0) {
                    row(item)
                    if isReordering {
                        ReorderHandle(
                            name: name(item),
                            canMoveUp: index > 0,
                            canMoveDown: index < items.count - 1,
                            onMoveUp: { move(item.id, index - 1) },
                            onMoveDown: { move(item.id, index + 1) }
                        )
                        .highPriorityGesture(drag(item))
                        .padding(.trailing, 4)
                    }
                }
                .background(held == item.id ? Palette.fill : Palette.card)
                .onGeometryChange(for: ClosedRange<Double>.self) { proxy in
                    let frame = proxy.frame(in: .named(reorderSpace))
                    return Double(frame.minY)...Double(frame.maxY)
                } action: { frame in
                    rowFrames[item.id] = frame
                }
            }
        }
        .coordinateSpace(.named(reorderSpace))
        .sensoryFeedback(.selection, trigger: items.map(\.id))
    }

    private func drag(_ item: Item) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(reorderSpace))
            .onChanged { value in
                held = item.id
                guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
                let rows = items.compactMap { rowFrames[$0.id] }
                guard rows.count == items.count else { return }
                let destination = Reordering.destination(ofRow: index, draggedTo: value.location.y, rows: rows)
                if destination != index { move(item.id, destination) }
            }
            .onEnded { _ in held = nil }
    }
}

#Preview("Light") {
    @Previewable @State var order = DetailOrder.standard
    ReorderableRows(
        items: order.kinds,
        isReordering: true,
        name: \.fieldLabel,
        move: { order.move($0, to: $1) }
    ) { kind in
        Text(kind.fieldLabel)
            .typography(.body)
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .padding(.leading, 16)
    }
    .card(cornerRadius: 14)
    .padding(16)
    .background(Palette.bg)
}

#Preview("Dark") {
    @Previewable @State var order = DetailOrder.standard
    ReorderableRows(
        items: order.kinds,
        isReordering: true,
        name: \.fieldLabel,
        move: { order.move($0, to: $1) }
    ) { kind in
        Text(kind.fieldLabel)
            .typography(.body)
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .padding(.leading, 16)
    }
    .card(cornerRadius: 14)
    .padding(16)
    .background(Palette.bg)
    .preferredColorScheme(.dark)
}

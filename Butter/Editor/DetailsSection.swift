import SwiftUI

/// Prep time, Bake time and Serves, in the recipe's own order.
struct DetailsSection: View {
    @Binding var draft: RecipeDraft
    @State private var isReordering = false

    var body: some View {
        EditorSection(title: "Details", reorder: .init(isOn: $isReordering)) {
            ReorderableRows(
                items: draft.detailOrder.kinds,
                isReordering: isReordering,
                name: \.fieldLabel,
                move: { draft.detailOrder.move($0, to: $1) }
            ) { kind in
                HStack {
                    Text(kind.fieldLabel)
                        .typography(.body)
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    if isReordering {
                        Text(kind.text(for: draft[detail: kind]))
                            .typography(.body)
                            .foregroundStyle(draft[detail: kind] == nil ? Palette.muted : Palette.ink)
                            .padding(.trailing, 4)
                    } else {
                        WholeNumberField(value: $draft[detail: kind], label: kind.fieldLabel, unit: kind.unit)
                    }
                }
                .padding(.leading, 16)
                .padding(.trailing, isReordering ? 0 : 8)
                .frame(minHeight: 52)
            }
            .card(cornerRadius: 14)

            Text("Type a whole number, or leave blank to skip it.")
                .typography(.caption)
                .foregroundStyle(Palette.muted)
                .padding(.horizontal, 4)
        }
    }
}

#if DEBUG
#Preview("Light") {
    @Previewable @State var draft = PreviewSamples.draft()
    DetailsSection(draft: $draft)
        .padding(16)
        .background(Palette.bg)
}

#Preview("Dark") {
    @Previewable @State var draft = PreviewSamples.draft(PreviewSamples.sandwich)
    DetailsSection(draft: $draft)
        .padding(16)
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}
#endif

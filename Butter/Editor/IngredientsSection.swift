import SwiftUI

/// One text field per ingredient, each removable, with Add Ingredient below.
struct IngredientsSection: View {
    @Binding var draft: RecipeDraft
    @State private var isReordering = false
    @FocusState private var focused: RecipeDraft.Line.ID?

    var body: some View {
        let lines = draft.ingredients
        EditorSection(
            title: "Ingredients",
            reorder: .init(isOn: $isReordering, isEnabled: lines.count >= 2)
        ) {
            VStack(spacing: 0) {
                ReorderableRows(
                    items: lines,
                    isReordering: isReordering && lines.count >= 2,
                    name: { line in "ingredient \(number(of: line))" },
                    move: { draft.ingredients.move(id: $0, to: $1) }
                ) { line in
                    HStack(spacing: 4) {
                        if isReordering {
                            Text(line.text)
                                .typography(.body)
                                .foregroundStyle(Palette.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            TextField("Ingredient \(number(of: line))", text: text(of: line))
                                .typography(.body)
                                .foregroundStyle(Palette.ink)
                                .focused($focused, equals: line.id)
                            Button {
                                draft.removeIngredient(id: line.id)
                            } label: {
                                Image(systemName: "minus.circle")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(Palette.danger)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plainLabel)
                            .accessibilityLabel("Remove ingredient \(number(of: line))")
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, isReordering ? 0 : 8)
                    .frame(minHeight: 52)
                }
                if !lines.isEmpty { CardDivider() }
                AddRowButton(title: "Add Ingredient") {
                    focused = draft.addIngredient()
                }
            }
            .card(cornerRadius: 14)
        }
        .onChange(of: lines.count) { _, count in
            if count < 2 { isReordering = false }
        }
    }

    private func number(of line: RecipeDraft.Line) -> Int {
        (draft.ingredients.firstIndex { $0.id == line.id } ?? 0) + 1
    }

    private func text(of line: RecipeDraft.Line) -> Binding<String> {
        Binding {
            draft.ingredients.first { $0.id == line.id }?.text ?? ""
        } set: { text in
            if let index = draft.ingredients.firstIndex(where: { $0.id == line.id }) {
                draft.ingredients[index].text = text
            }
        }
    }
}

#if DEBUG
#Preview("Light") {
    @Previewable @State var draft = PreviewSamples.draft()
    ScrollView {
        IngredientsSection(draft: $draft)
            .padding(16)
    }
    .background(Palette.bg)
}

#Preview("Dark") {
    @Previewable @State var draft = RecipeDraft()
    IngredientsSection(draft: $draft)
        .padding(16)
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}
#endif

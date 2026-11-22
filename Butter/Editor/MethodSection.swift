import SwiftUI

/// Numbered, multi-line steps with Add Step below. Numbers always follow the current order.
struct MethodSection: View {
    @Binding var draft: RecipeDraft
    @State private var isReordering = false
    @FocusState private var focused: RecipeDraft.Line.ID?

    var body: some View {
        let steps = draft.steps
        EditorSection(
            title: "Method",
            reorder: .init(isOn: $isReordering, isEnabled: steps.count >= 2)
        ) {
            VStack(spacing: 0) {
                ReorderableRows(
                    items: steps,
                    isReordering: isReordering && steps.count >= 2,
                    name: { step in "step \(number(of: step))" },
                    move: { draft.steps.move(id: $0, to: $1) }
                ) { step in
                    HStack(alignment: .top, spacing: 12) {
                        StepNumberBadge(number: number(of: step), size: .editor)
                            .padding(.top, 2)
                        Group {
                            if isReordering {
                                Text(step.text)
                                    .lineLimit(3)
                            } else {
                                TextField("Step \(number(of: step))", text: text(of: step), axis: .vertical)
                                    .lineLimit(3...)
                                    .focused($focused, equals: step.id)
                            }
                        }
                        .typography(.body)
                        .foregroundStyle(Palette.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                    }
                    .padding(.vertical, 12)
                    .padding(.leading, 16)
                    .padding(.trailing, isReordering ? 0 : 8)
                }
                if !steps.isEmpty { CardDivider() }
                AddRowButton(title: "Add Step") {
                    focused = draft.addStep()
                }
            }
            .card(cornerRadius: 14)
        }
        .onChange(of: steps.count) { _, count in
            if count < 2 { isReordering = false }
        }
    }

    private func number(of step: RecipeDraft.Line) -> Int {
        (draft.steps.firstIndex { $0.id == step.id } ?? 0) + 1
    }

    private func text(of step: RecipeDraft.Line) -> Binding<String> {
        Binding {
            draft.steps.first { $0.id == step.id }?.text ?? ""
        } set: { text in
            if let index = draft.steps.firstIndex(where: { $0.id == step.id }) {
                draft.steps[index].text = text
            }
        }
    }
}

#if DEBUG
#Preview("Light") {
    @Previewable @State var draft = PreviewSamples.draft()
    ScrollView {
        MethodSection(draft: $draft)
            .padding(16)
    }
    .background(Palette.bg)
}

#Preview("Dark") {
    @Previewable @State var draft = PreviewSamples.draft()
    ScrollView {
        MethodSection(draft: $draft)
            .padding(16)
    }
    .background(Palette.bg)
    .preferredColorScheme(.dark)
}
#endif

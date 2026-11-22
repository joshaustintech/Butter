import SwiftUI

/// A titled, multi-line text box in a card. One entry per line.
struct RecipeTextField: View {
    let label: String
    let hint: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: ButterSpacing.xs) {
            Text(label)
                .font(.headline)
                .foregroundStyle(Color.butterLabel)
            TextEditor(text: $text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 120)
                .accessibilityLabel(label)
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(hint)
                            .font(.body)
                            .foregroundStyle(Color.butterLabelSecondary)
                            .padding(.top, ButterSpacing.xs)
                            .padding(.leading, ButterSpacing.xxs)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
                .butterCard()
        }
    }
}

#Preview("Light") {
    @Previewable @State var text = ""
    RecipeTextField(label: "Ingredients", hint: "One per line", text: $text)
        .padding(ButterSpacing.md)
        .background(Color.butterBackground)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    @Previewable @State var text = "2 eggs\n1 cup flour"
    RecipeTextField(label: "Ingredients", hint: "One per line", text: $text)
        .padding(ButterSpacing.md)
        .background(Color.butterBackground)
        .preferredColorScheme(.dark)
}

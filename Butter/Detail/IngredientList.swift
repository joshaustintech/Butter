import SwiftUI

/// The ingredients card: a `leaf` bullet before each line, rules between them.
struct IngredientList: View {
    let ingredients: [NonBlankText]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(ingredients.enumerated()), id: \.offset) { index, ingredient in
                if index > 0 { CardDivider() }
                HStack(spacing: 12) {
                    Circle()
                        .fill(Palette.leaf)
                        .frame(width: 7, height: 7)
                        .accessibilityHidden(true)
                    Text(ingredient.value)
                        .typography(.body)
                        .foregroundStyle(Palette.ink)
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .card(cornerRadius: 16)
    }
}

#if DEBUG
#Preview("Light") {
    IngredientList(ingredients: PreviewSamples.galette.ingredients)
        .padding(20)
        .background(Palette.bg)
}

#Preview("Dark") {
    IngredientList(ingredients: PreviewSamples.galette.ingredients)
        .padding(20)
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}
#endif

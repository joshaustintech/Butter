import SwiftUI

/// The rounded card holding the arranged rows, or the no-results state.
struct RecipeCard: View {
    let recipes: [Recipe]
    let sort: RecipeSort
    let query: String

    var body: some View {
        let arranged = RecipeCatalog.arrange(recipes, by: sort, matching: query)
        let tints = RecipeCatalog.tints(for: recipes)
        if arranged.isEmpty {
            ContentUnavailableView.search(text: query.trimmingCharacters(in: .whitespacesAndNewlines))
                .foregroundStyle(Palette.muted)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(arranged.enumerated()), id: \.element.id) { index, recipe in
                    if index > 0 { CardDivider() }
                    NavigationLink(value: recipe) {
                        RecipeRow(content: recipe.content, tint: tints[recipe.id] ?? .sage)
                    }
                    .buttonStyle(.cardRow)
                }
            }
            .card(cornerRadius: 16)
        }
    }
}

#if DEBUG
#Preview("Light") {
    NavigationStack {
        RecipeCard(recipes: PreviewSamples.recipes, sort: .latest, query: "")
            .padding()
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Palette.bg)
    }
}

#Preview("Dark") {
    NavigationStack {
        RecipeCard(recipes: PreviewSamples.recipes, sort: .name, query: "")
            .padding()
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Palette.bg)
    }
    .preferredColorScheme(.dark)
}

#Preview("No Results, Light") {
    RecipeCard(recipes: PreviewSamples.recipes, sort: .latest, query: "Zucchini")
        .background(Palette.bg)
}

#Preview("No Results, Dark") {
    RecipeCard(recipes: PreviewSamples.recipes, sort: .latest, query: "Zucchini")
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}
#endif

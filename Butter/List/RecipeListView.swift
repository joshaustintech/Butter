import SwiftData
import SwiftUI

/// The root screen: every saved recipe, searchable and sortable.
struct RecipeListView: View {
    @Query private var recipes: [Recipe]
    @State private var sort = RecipeSort.latest
    @State private var query = ""
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    RecipeListHeader(
                        subtitle: RecipeCatalog.subtitle(count: recipes.count, sort: sort),
                        onAdd: { isCreating = true }
                    )
                    if recipes.isEmpty {
                        RecipeListEmpty()
                    } else {
                        SearchField(text: $query)
                        SortControl(selection: $sort)
                        RecipeCard(recipes: recipes, sort: sort, query: query)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.immediately)
            .background(Palette.bg)
            .navigationTitle("Recipes")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
        }
        .sheet(isPresented: $isCreating) {
            RecipeEditorView(mode: .new)
        }
    }
}

#if DEBUG
#Preview("Light") {
    RecipeListView()
        .modelContainer(PreviewSamples.container)
}

#Preview("Dark") {
    RecipeListView()
        .modelContainer(PreviewSamples.container)
        .preferredColorScheme(.dark)
}

#Preview("Empty, Light") {
    RecipeListView()
        .modelContainer(PreviewSamples.emptyContainer)
}

#Preview("Empty, Dark") {
    RecipeListView()
        .modelContainer(PreviewSamples.emptyContainer)
        .preferredColorScheme(.dark)
}
#endif

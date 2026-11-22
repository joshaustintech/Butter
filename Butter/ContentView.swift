import SwiftData
import SwiftUI

/// The main screen. It owns whether the add-recipe sheet is showing.
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.savedDate, order: .reverse) private var recipes: [Recipe]
    @State private var showingAddRecipe = false

    var body: some View {
        NavigationStack {
            Group {
                if recipes.isEmpty {
                    ContentUnavailableView(
                        "No Recipes Yet",
                        systemImage: "fork.knife",
                        description: Text("Recipes you save will appear here.")
                    )
                } else {
                    RecipeListView(recipes: recipes)
                }
            }
            .navigationTitle("Butter")
            .background(Color.butterBackground)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    AddRecipeButton { showingAddRecipe = true }
                }
            }
            .sheet(isPresented: $showingAddRecipe) {
                AddRecipeForm(
                    onSave: { draft in
                        // #17 will move this save behind the Recipe store.
                        draft.save(in: modelContext)
                        showingAddRecipe = false
                    },
                    onClose: { showingAddRecipe = false }
                )
            }
        }
    }
}

#Preview("Light") {
    ContentView()
        .modelContainer(try! makeContainer(inMemory: true))
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ContentView()
        .modelContainer(try! makeContainer(inMemory: true))
        .preferredColorScheme(.dark)
}

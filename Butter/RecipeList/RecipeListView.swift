import SwiftUI

/// A plain list of saved Recipe titles, in the order given. Tapping a row opens its details.
struct RecipeListView: View {
    let recipes: [Recipe]

    var body: some View {
        List(recipes) { recipe in
            NavigationLink(value: recipe) {
                RecipeRow(title: recipe.title)
            }
            .listRowBackground(Color.butterSurface)
        }
        .scrollContentBackground(.hidden)
        .background(Color.butterBackground)
    }
}

#Preview("Light") {
    RecipeListView(recipes: [Recipe(title: "Lemon pancakes"), Recipe(title: "Tomato soup")])
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    RecipeListView(recipes: [Recipe(title: "Lemon pancakes"), Recipe(title: "Tomato soup")])
        .preferredColorScheme(.dark)
}

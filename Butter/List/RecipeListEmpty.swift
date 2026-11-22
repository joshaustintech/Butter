import SwiftUI

/// Shown before any recipe is saved.
struct RecipeListEmpty: View {
    var body: some View {
        ContentUnavailableView {
            Text("No Recipes Yet")
                .typography(.sectionTitle)
                .foregroundStyle(Palette.ink)
        } description: {
            Text("Tap + to add your first recipe.")
                .typography(.body)
                .foregroundStyle(Palette.muted)
        }
        .padding(.top, 80)
    }
}

#Preview("Light") {
    RecipeListEmpty()
        .background(Palette.bg)
}

#Preview("Dark") {
    RecipeListEmpty()
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}

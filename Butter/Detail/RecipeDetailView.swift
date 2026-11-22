import SwiftData
import SwiftUI

/// A saved recipe, read-only. Edit opens the editor as a sheet; if the recipe
/// is deleted there, this screen pops back to the list.
struct RecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false

    var body: some View {
        ZStack {
            if recipe.isGone {
                Rectangle().fill(Palette.bg).ignoresSafeArea()
            } else {
                RecipeDetailContent(content: recipe.content, createdAt: recipe.createdAt)
            }
        }
        .overlay(alignment: .top) {
            DetailPills(onBack: { dismiss() }, onEdit: { isEditing = true })
        }
        .navigationTitle(recipe.isGone ? "" : recipe.title)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isEditing, onDismiss: popIfDeleted) {
            RecipeEditorView(mode: .edit(recipe))
        }
    }

    private func popIfDeleted() {
        if recipe.isGone { dismiss() }
    }
}

#if DEBUG
#Preview("Light") {
    NavigationStack {
        RecipeDetailView(recipe: PreviewSamples.recipe())
    }
    .modelContainer(PreviewSamples.container)
}

#Preview("Dark") {
    NavigationStack {
        RecipeDetailView(recipe: PreviewSamples.recipe())
    }
    .modelContainer(PreviewSamples.container)
    .preferredColorScheme(.dark)
}
#endif

import SwiftUI

/// Tells the person an imported webpage is already saved, and offers to open the
/// Recipe they already have. Shown for the Duplicate outcome of an import.
struct AlreadySavedMessage: View {
    let recipeTitle: String
    /// Opens the existing Recipe. The screen that shows Recipes wires this later.
    let openRecipe: () -> Void

    /// Builds the message for an import outcome. Returns nil when a new Recipe
    /// was saved, because there is nothing to say then.
    init?(outcome: RecipeImportOutcome, openRecipe: @escaping () -> Void) {
        guard case .duplicate(let recipe) = outcome else { return nil }
        self.init(recipeTitle: recipe.title, openRecipe: openRecipe)
    }

    init(recipeTitle: String, openRecipe: @escaping () -> Void) {
        self.recipeTitle = recipeTitle
        self.openRecipe = openRecipe
    }

    private var detail: String {
        recipeTitle.isEmpty
            ? "Nothing new was added, and your saved Recipe is unchanged."
            : "Nothing new was added. \u{201C}\(recipeTitle)\u{201D} is unchanged."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ButterSpacing.md) {
            VStack(alignment: .leading, spacing: ButterSpacing.xs) {
                Label {
                    Text("Already saved")
                        .font(.headline)
                        .foregroundStyle(Color.butterLabel)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.butterAccent)
                }
                Text(detail)
                    .font(.body)
                    .foregroundStyle(Color.butterLabelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)

            Button("Open Recipe", action: openRecipe)
                .buttonStyle(.butterSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .butterCard()
    }
}

#Preview("Light") {
    AlreadySavedMessage(recipeTitle: "Lemon Herb Chicken") {}
        .padding(ButterSpacing.lg)
        .background(Color.butterBackground)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    AlreadySavedMessage(recipeTitle: "Lemon Herb Chicken") {}
        .padding(ButterSpacing.lg)
        .background(Color.butterBackground)
        .preferredColorScheme(.dark)
}

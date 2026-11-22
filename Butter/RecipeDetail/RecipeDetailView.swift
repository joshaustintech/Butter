import SwiftUI

/// Shows the full details of a saved Recipe: title, photo, Ingredients, Steps, and Source.
struct RecipeDetailView: View {
    let recipe: Recipe

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ButterSpacing.lg) {
                Text(recipe.title)
                    .font(.butterDisplay(.title))
                    .foregroundStyle(Color.butterLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let data = recipe.photo, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 240)
                        .clipShape(RoundedRectangle(cornerRadius: ButterRadius.large, style: .continuous))
                }

                if !recipe.orderedIngredients.isEmpty {
                    ingredientsCard
                }

                if !recipe.orderedSteps.isEmpty {
                    stepsCard
                }

                footerSection
            }
            .padding(ButterSpacing.md)
        }
        .background(Color.butterBackground)
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var ingredientsCard: some View {
        VStack(alignment: .leading, spacing: ButterSpacing.sm) {
            Text("Ingredients")
                .font(.headline)
                .foregroundStyle(Color.butterLabel)

            ForEach(recipe.orderedIngredients, id: \.self) { ingredient in
                Text(ingredient.text)
                    .font(.body)
                    .foregroundStyle(Color.butterLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .butterCard()
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: ButterSpacing.md) {
            Text("Steps")
                .font(.headline)
                .foregroundStyle(Color.butterLabel)

            ForEach(Array(recipe.orderedSteps.enumerated()), id: \.element) { index, step in
                HStack(alignment: .top, spacing: ButterSpacing.sm) {
                    Text("\(index + 1)")
                        .font(.headline)
                        .foregroundStyle(Color.butterLabelSecondary)
                        .frame(minWidth: 20, alignment: .trailing)

                    Text(step.text)
                        .font(.body)
                        .foregroundStyle(Color.butterLabel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .butterCard()
    }

    private var footerSection: some View {
        VStack(alignment: .leading, spacing: ButterSpacing.xs) {
            if recipe.source?.kind == .webpage, let url = recipe.source?.url {
                Link(destination: url) {
                    HStack(spacing: ButterSpacing.xs) {
                        Image(systemName: "safari")
                        Text(url.host ?? "Original Recipe")
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.butterAccent)
                    .frame(minHeight: 44, alignment: .leading)
                }
            }

            Text("Saved \(recipe.savedDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(Color.butterLabelSecondary)
        }
    }
}

#Preview("Light - Full") {
    NavigationStack {
        RecipeDetailView(recipe: Recipe(
            title: "Lemon pancakes",
            ingredients: ["2 eggs", "1 cup flour", "1 lemon, zested and juiced", "1 cup buttermilk"],
            steps: ["Whisk eggs and buttermilk together.", "Stir in flour and lemon zest.", "Cook on a hot buttered skillet until golden."],
            source: Source(webpage: URL(string: "https://example.com/lemon-pancakes")!)
        ))
    }
    .preferredColorScheme(.light)
}

#Preview("Dark - Full") {
    NavigationStack {
        RecipeDetailView(recipe: Recipe(
            title: "Lemon pancakes",
            ingredients: ["2 eggs", "1 cup flour", "1 lemon, zested and juiced", "1 cup buttermilk"],
            steps: ["Whisk eggs and buttermilk together.", "Stir in flour and lemon zest.", "Cook on a hot buttered skillet until golden."],
            source: Source(webpage: URL(string: "https://example.com/lemon-pancakes")!)
        ))
    }
    .preferredColorScheme(.dark)
}

#Preview("Light - Title Only") {
    NavigationStack {
        RecipeDetailView(recipe: Recipe(title: "Grandma's Soup"))
    }
    .preferredColorScheme(.light)
}

#Preview("Dark - Title Only") {
    NavigationStack {
        RecipeDetailView(recipe: Recipe(title: "Grandma's Soup"))
    }
    .preferredColorScheme(.dark)
}

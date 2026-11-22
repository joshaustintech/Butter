import SwiftUI

/// Shows the full details of a saved Recipe: title, photo, Ingredients, Steps, and Source.
struct RecipeDetailView: View {
    let recipe: Recipe
    /// True once the serif heading has scrolled out of view, so the bar shows the title.
    @State private var headingHidden = false
    @ScaledMetric(relativeTo: .headline) private var stepNumberWidth = 20.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ButterSpacing.lg) {
                Text(recipe.title)
                    .font(.butterDisplay(.title))
                    .foregroundStyle(Color.butterLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onScrollVisibilityChange(threshold: 0.1) { visible in
                        headingHidden = !visible
                    }

                if let data = recipe.photo, let uiImage = UIImage(data: data) {
                    photoCard(uiImage)
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
        .navigationTitle(headingHidden ? recipe.title : "")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func photoCard(_ image: UIImage) -> some View {
        RecipePhoto(image: image)
            .butterCard()
    }

    private var ingredientsCard: some View {
        VStack(alignment: .leading, spacing: ButterSpacing.sm) {
            FieldHeader(label: "Ingredients")

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
            FieldHeader(label: "Steps")

            ForEach(Array(recipe.orderedSteps.enumerated()), id: \.element) { index, step in
                HStack(alignment: .top, spacing: ButterSpacing.sm) {
                    Text("\(index + 1)")
                        .font(.headline)
                        .foregroundStyle(Color.butterLabelSecondary)
                        .frame(minWidth: stepNumberWidth, alignment: .trailing)

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
            if let url = recipe.source?.webpageURL {
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

            footerDate("Saved", recipe.savedDate)

            if recipe.updatedDate > recipe.savedDate {
                footerDate("Updated", recipe.updatedDate)
            }
        }
    }

    private func footerDate(_ label: String, _ date: Date) -> some View {
        Text("\(label) \(date.formatted(date: .abbreviated, time: .omitted))")
            .font(.caption)
            .foregroundStyle(Color.butterLabelSecondary)
    }
}

extension Recipe {
    /// A solid butter-colored square, rendered so previews have a real photo.
    static var previewPhoto: Data {
        UIGraphicsImageRenderer(size: CGSize(width: 400, height: 300)).pngData { context in
            UIColor(Color.butterPrimary).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 400, height: 300))
        }
    }

    static func preview(photo: Data? = nil, source: Source? = nil, updated: Bool = false) -> Recipe {
        let recipe = Recipe(
            title: "Lemon pancakes",
            ingredients: ["2 eggs", "1 cup flour", "1 lemon, zested and juiced", "1 cup buttermilk"],
            steps: ["Whisk eggs and buttermilk together.", "Stir in flour and lemon zest.", "Cook on a hot buttered skillet until golden."],
            photo: photo,
            source: source,
            savedDate: Date(timeIntervalSinceNow: -86_400 * 7)
        )
        if updated { recipe.touch() }
        return recipe
    }

    static var previewFull: Recipe {
        preview(photo: previewPhoto, source: Source(webpage: URL(string: "https://example.com/lemon-pancakes")!), updated: true)
    }
}

#Preview("Light - Full") {
    NavigationStack { RecipeDetailView(recipe: .previewFull) }
        .preferredColorScheme(.light)
}

#Preview("Dark - Full") {
    NavigationStack { RecipeDetailView(recipe: .previewFull) }
        .preferredColorScheme(.dark)
}

#Preview("Light - Photographed Page") {
    NavigationStack { RecipeDetailView(recipe: .preview(source: Source(photographedPage: Recipe.previewPhoto))) }
        .preferredColorScheme(.light)
}

#Preview("Dark - Photographed Page") {
    NavigationStack { RecipeDetailView(recipe: .preview(source: Source(photographedPage: Recipe.previewPhoto))) }
        .preferredColorScheme(.dark)
}

#Preview("Light - Title Only") {
    NavigationStack { RecipeDetailView(recipe: Recipe(title: "Grandma's Soup")) }
        .preferredColorScheme(.light)
}

#Preview("Dark - Title Only") {
    NavigationStack { RecipeDetailView(recipe: Recipe(title: "Grandma's Soup")) }
        .preferredColorScheme(.dark)
}

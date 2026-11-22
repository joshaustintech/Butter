import SwiftUI

/// The scrolling body of the detail screen. Sections with nothing in them are left out.
struct RecipeDetailContent: View {
    let content: RecipeContent
    let createdAt: Date

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                RecipeHero(letter: Monogram.letter(in: content.title.value), photo: content.photo)
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(content.title.value)
                            .typography(.detailTitle)
                            .foregroundStyle(Palette.ink)
                            .accessibilityAddTraits(.isHeader)
                        RatingLine(rating: content.rating, added: AddedDate.text(for: createdAt))
                    }
                    if !content.stats.isEmpty {
                        StatTiles(stats: content.stats)
                    }
                    if !content.ingredients.isEmpty {
                        DetailSection(title: "Ingredients") {
                            IngredientList(ingredients: content.ingredients)
                        }
                    }
                    if !content.steps.isEmpty {
                        DetailSection(title: "Method") {
                            MethodList(steps: content.steps)
                        }
                    }
                    if let review = content.reviewNotes {
                        DetailSection(title: "My Review") {
                            ReviewCard(review: review)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Palette.bg)
    }
}

#if DEBUG
#Preview("Light") {
    RecipeDetailContent(content: PreviewSamples.galette, createdAt: PreviewSamples.addedDate)
}

#Preview("Dark") {
    RecipeDetailContent(content: PreviewSamples.galette, createdAt: PreviewSamples.addedDate)
        .preferredColorScheme(.dark)
}

#Preview("Sparse, Light") {
    RecipeDetailContent(content: PreviewSamples.sandwich, createdAt: PreviewSamples.addedDate)
}

#Preview("Sparse, Dark") {
    RecipeDetailContent(content: PreviewSamples.sandwich, createdAt: PreviewSamples.addedDate)
        .preferredColorScheme(.dark)
}

#Preview("Title Only, Light") {
    RecipeDetailContent(content: PreviewSamples.bare, createdAt: PreviewSamples.addedDate)
}

#Preview("Title Only, Dark") {
    RecipeDetailContent(content: PreviewSamples.bare, createdAt: PreviewSamples.addedDate)
        .preferredColorScheme(.dark)
}
#endif

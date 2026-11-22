import SwiftUI

/// One recipe in the list: tile, serif title, meta line and chevron.
struct RecipeRow: View {
    let content: RecipeContent
    let tint: TileTint

    var body: some View {
        HStack(spacing: 14) {
            RecipeTile(letter: Monogram.letter(in: content.title.value), photo: content.photo, tint: tint)
            VStack(alignment: .leading, spacing: 4) {
                Text(content.title.value)
                    .typography(.rowTitle)
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.leading)
                RecipeMetaLine(summary: content.summary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.chevron)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(minHeight: 60)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview("Light") {
    VStack(spacing: 0) {
        RecipeRow(content: PreviewSamples.galette, tint: .rose)
        CardDivider()
        RecipeRow(content: PreviewSamples.bare, tint: .sage)
    }
    .card()
    .padding()
    .background(Palette.bg)
}

#Preview("Dark") {
    VStack(spacing: 0) {
        RecipeRow(content: PreviewSamples.galette, tint: .rose)
        CardDivider()
        RecipeRow(content: PreviewSamples.bare, tint: .sage)
    }
    .card()
    .padding()
    .background(Palette.bg)
    .preferredColorScheme(.dark)
}
#endif

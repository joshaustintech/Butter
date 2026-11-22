import SwiftUI

/// `★ 4.5   1 hr 20 min` beneath a row's title, or "No details yet".
struct RecipeMetaLine: View {
    let summary: RecipeSummary

    var body: some View {
        HStack(spacing: 10) {
            switch summary {
            case let .details(rating, time):
                if let rating {
                    HStack(spacing: 4) {
                        Image(systemName: StarFill.full.symbolName)
                            .foregroundStyle(Palette.star)
                        Text(rating)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Rated \(rating) out of 5")
                }
                if let time {
                    Text(time)
                }
            case .noDetails:
                Text(summary.noDetailsText)
            }
        }
        .typography(.rowMeta)
        .foregroundStyle(Palette.muted)
    }
}

#Preview("Light") {
    VStack(alignment: .leading, spacing: 8) {
        RecipeMetaLine(summary: .details(rating: "4.5", time: "1 hr 20 min"))
        RecipeMetaLine(summary: .details(rating: nil, time: "10 min"))
        RecipeMetaLine(summary: .noDetails)
    }
    .padding()
    .background(Palette.card)
}

#Preview("Dark") {
    VStack(alignment: .leading, spacing: 8) {
        RecipeMetaLine(summary: .details(rating: "4.5", time: "1 hr 20 min"))
        RecipeMetaLine(summary: .details(rating: nil, time: "10 min"))
        RecipeMetaLine(summary: .noDetails)
    }
    .padding()
    .background(Palette.card)
    .preferredColorScheme(.dark)
}

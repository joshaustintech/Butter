import SwiftUI

/// Stars, the rating and the date added; only the date when unrated.
struct RatingLine: View {
    let rating: Rating?
    let added: String

    var body: some View {
        HStack(spacing: 8) {
            if let rating {
                StarRow(rating: rating)
                Text(rating.formatted)
                    .accessibilityHidden(true)
                Text("·")
                    .accessibilityHidden(true)
            }
            Text(added)
        }
        .typography(.ratingLine)
        .foregroundStyle(Palette.muted)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Light") {
    VStack(alignment: .leading, spacing: 12) {
        RatingLine(rating: Rating(4.5), added: "Added Nov 18")
        RatingLine(rating: nil, added: "Added Nov 18")
    }
    .padding()
    .background(Palette.bg)
}

#Preview("Dark") {
    VStack(alignment: .leading, spacing: 12) {
        RatingLine(rating: Rating(4.5), added: "Added Nov 18")
        RatingLine(rating: nil, added: "Added Nov 18")
    }
    .padding()
    .background(Palette.bg)
    .preferredColorScheme(.dark)
}

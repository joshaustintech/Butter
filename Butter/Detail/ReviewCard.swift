import SwiftUI

/// The review notes in serif italic, on a card.
struct ReviewCard: View {
    let review: NonBlankText

    var body: some View {
        Text(review.value)
            .typography(.review)
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .card(cornerRadius: 16)
    }
}

#Preview("Light") {
    ReviewCard(review: NonBlankText("Tart and sweet in just the right measure.")!)
        .padding(20)
        .background(Palette.bg)
}

#Preview("Dark") {
    ReviewCard(review: NonBlankText("Tart and sweet in just the right measure.")!)
        .padding(20)
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}

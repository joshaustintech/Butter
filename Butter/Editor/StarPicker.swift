import SwiftUI

/// Five 52 pt star targets, each split into a left (half-star) and right
/// (whole-star) half. VoiceOver treats the row as one adjustable control.
struct StarPicker: View {
    @Binding var rating: Rating?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...5, id: \.self) { star in
                ZStack {
                    Image(systemName: (rating?.fill(ofStar: star) ?? .empty).symbolName)
                        .font(.system(size: 28))
                        .foregroundStyle(Palette.star)
                    HStack(spacing: 0) {
                        target(star: star, half: .leading)
                        target(star: star, half: .trailing)
                    }
                }
                .frame(width: 52, height: 52)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating")
        .accessibilityValue(Rating.outOfFive(rating))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: rating = Rating.raised(rating)
            case .decrement: rating = rating?.lowered()
            @unknown default: break
            }
        }
    }

    private func target(star: Int, half: StarHalf) -> some View {
        Button {
            rating = Rating(star: star, half: half)
        } label: {
            Color.clear
                .frame(width: 26, height: 52)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("Light") {
    @Previewable @State var rating = Rating(3.5)
    StarPicker(rating: $rating)
        .padding()
        .background(Palette.card)
}

#Preview("Dark") {
    @Previewable @State var rating: Rating?
    StarPicker(rating: $rating)
        .padding()
        .background(Palette.card)
        .preferredColorScheme(.dark)
}

import SwiftUI

/// Five read-only stars showing a rating, half stars included.
struct StarRow: View {
    let rating: Rating
    var starSize: CGFloat = 16

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: rating.fill(ofStar: star).symbolName)
                    .font(.system(size: starSize))
                    .foregroundStyle(Palette.star)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(rating.formatted) out of 5 stars")
    }
}

#Preview("Light") {
    VStack(alignment: .leading) {
        StarRow(rating: Rating(4.5)!)
        StarRow(rating: Rating(1)!, starSize: 28)
    }
    .padding()
    .background(Palette.bg)
}

#Preview("Dark") {
    VStack(alignment: .leading) {
        StarRow(rating: Rating(4.5)!)
        StarRow(rating: Rating(1)!, starSize: 28)
    }
    .padding()
    .background(Palette.bg)
    .preferredColorScheme(.dark)
}

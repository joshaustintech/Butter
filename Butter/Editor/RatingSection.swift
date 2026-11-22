import SwiftUI

/// Half-star rating: tap a star's left half for x.5 or right half for a whole
/// star; − and + step by half a star; Clear removes the rating.
struct RatingSection: View {
    @Binding var rating: Rating?

    var body: some View {
        EditorSection(title: "My Rating") {
            VStack(spacing: 2) {
                StarPicker(rating: $rating)
                HStack(spacing: 0) {
                    Text(Rating.outOfFive(rating))
                        .typography(.body)
                        .foregroundStyle(rating == nil ? Palette.muted : Palette.ink)
                        .padding(.leading, 8)
                    Spacer()
                    Button("−") { rating = rating?.lowered() }
                        .typography(.stepper)
                        .frame(width: 44, height: 44)
                        .disabled(rating == nil)
                        .accessibilityLabel("Decrease rating by half a star")
                    Button("+") { rating = Rating.raised(rating) }
                        .typography(.stepper)
                        .frame(width: 44, height: 44)
                        .disabled(rating == .maximum)
                        .accessibilityLabel("Increase rating by half a star")
                    Button("Clear") { rating = nil }
                        .typography(.button)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                        .disabled(rating == nil)
                }
                .foregroundStyle(Palette.accent)
                .buttonStyle(.plainLabel)
            }
            .padding(8)
            .card(cornerRadius: 14)
        }
    }
}

#Preview("Light") {
    @Previewable @State var rating = Rating(4.5)
    RatingSection(rating: $rating)
        .padding(16)
        .background(Palette.bg)
}

#Preview("Dark") {
    @Previewable @State var rating: Rating?
    RatingSection(rating: $rating)
        .padding(16)
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}

import SwiftUI

/// The 1 pt `line` rule between rows in a card.
struct CardDivider: View {
    var body: some View {
        Rectangle()
            .fill(Palette.line)
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}

#Preview("Light") {
    CardDivider()
        .padding()
        .background(Palette.card)
}

#Preview("Dark") {
    CardDivider()
        .padding()
        .background(Palette.card)
        .preferredColorScheme(.dark)
}

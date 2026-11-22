import SwiftUI

/// One saved Recipe in the list: its title.
struct RecipeRow: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.body)
            .foregroundStyle(Color.butterLabel)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }
}

#Preview("Light") {
    RecipeRow(title: "Lemon pancakes")
        .padding(ButterSpacing.md)
        .background(Color.butterBackground)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    RecipeRow(title: "Lemon pancakes")
        .padding(ButterSpacing.md)
        .background(Color.butterBackground)
        .preferredColorScheme(.dark)
}

import SwiftUI

/// "Recipes" in large serif, the count and sort beneath, and the round + button.
struct RecipeListHeader: View {
    let subtitle: String
    let onAdd: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Recipes")
                    .typography(.listTitle)
                    .foregroundStyle(Palette.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle)
                    .typography(.listSubtitle)
                    .foregroundStyle(Palette.muted)
            }
            Spacer(minLength: 0)
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Palette.onAccent)
                    .frame(width: 44, height: 44)
                    .background(Palette.accent, in: Circle())
            }
            .buttonStyle(.plainLabel)
            .accessibilityLabel("New Recipe")
        }
    }
}

#Preview("Light") {
    RecipeListHeader(subtitle: "6 recipes · sorted by latest", onAdd: {})
        .padding()
        .background(Palette.bg)
}

#Preview("Dark") {
    RecipeListHeader(subtitle: "6 recipes · sorted by latest", onAdd: {})
        .padding()
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}

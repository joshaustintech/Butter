import SwiftUI

// Card surface.

struct ButterCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(ButterSpacing.md)
            .background(
                Color.butterSurface,
                in: RoundedRectangle(cornerRadius: ButterRadius.medium, style: .continuous)
            )
    }
}

extension View {
    /// Wraps content in a Cottage Butter surface card.
    func butterCard() -> some View {
        modifier(ButterCardModifier())
    }
}

/// Preview-only example showing the card with real content.
private struct ButterCardExample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: ButterSpacing.sm) {
            Text("Lemon Herb Chicken")
                .font(.butterDisplay(.title2))
                .foregroundStyle(Color.butterLabel)
            Text("4 ingredients, 3 steps")
                .font(.body)
                .foregroundStyle(Color.butterLabelSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .butterCard()
        .padding(ButterSpacing.lg)
        .background(Color.butterBackground)
    }
}

#Preview("Light") {
    ButterCardExample()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ButterCardExample()
        .preferredColorScheme(.dark)
}

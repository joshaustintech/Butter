import SwiftUI

/// The current Step in large text, with its position.
struct CookingStepCard: View {
    let position: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: ButterSpacing.md) {
            Text(position)
                .font(.headline)
                .foregroundStyle(Color.butterLabelSecondary)
            ScrollView {
                Text(text)
                    .font(.title)
                    .foregroundStyle(Color.butterLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(ButterSpacing.xl)
                    .butterCard()
            }
        }
    }
}

#Preview("Light") {
    CookingStepCard(position: "Step 2 of 5", text: "Add the sage leaves and cook until crisp, about two minutes.")
        .padding(ButterSpacing.xl)
        .background(Color.butterBackground)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    CookingStepCard(position: "Step 2 of 5", text: "Add the sage leaves and cook until crisp, about two minutes.")
        .padding(ButterSpacing.xl)
        .background(Color.butterBackground)
        .preferredColorScheme(.dark)
}

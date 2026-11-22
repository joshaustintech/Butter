import SwiftUI

/// The "All done" screen shown when a Cooking session ends.
struct CookingFinishedView: View {
    var onDone: () -> Void = {}

    var body: some View {
        VStack(spacing: ButterSpacing.xl) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.butterAccent)
                .accessibilityHidden(true)
            Text("All done")
                .font(.butterDisplay(.largeTitle))
                .foregroundStyle(Color.butterLabel)
            Text("Enjoy your meal.")
                .font(.body)
                .foregroundStyle(Color.butterLabelSecondary)
            Spacer()
            Button("Done", action: onDone)
                .buttonStyle(.butterPrimary)
        }
        .padding(ButterSpacing.xl)
    }
}

#Preview("Light") {
    CookingFinishedView()
        .background(Color.butterBackground)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    CookingFinishedView()
        .background(Color.butterBackground)
        .preferredColorScheme(.dark)
}

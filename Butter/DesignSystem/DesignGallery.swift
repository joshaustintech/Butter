import SwiftUI

// Preview-only visual check for the Cottage Butter tokens and components.

struct DesignGallery: View {
    @State private var selected = "Herbs"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ButterSpacing.xl) {
                Text("Cottage Butter")
                    .font(.butterDisplay(.largeTitle))
                    .foregroundStyle(Color.butterLabel)

                VStack(alignment: .leading, spacing: ButterSpacing.sm) {
                    Text("Today in the garden")
                        .font(.butterDisplay(.title2))
                        .foregroundStyle(Color.butterLabel)
                    Text("Water the basil")
                        .font(.body)
                        .foregroundStyle(Color.butterLabelSecondary)
                    Button("Mark done") {}
                        .buttonStyle(.butterPrimary)
                    Button("Maybe later") {}
                        .buttonStyle(.butterSecondary)
                }
                .butterCard()

                HStack(spacing: ButterSpacing.xs) {
                    ForEach(["Herbs", "Blooms", "Berries"], id: \.self) { item in
                        ButterChip(title: item, isSelected: selected == item) {
                            selected = item
                        }
                    }
                }
            }
            .padding(ButterSpacing.lg)
        }
        .background(Color.butterBackground)
        .butterTheme()
    }
}

#Preview("Light") {
    DesignGallery()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    DesignGallery()
        .preferredColorScheme(.dark)
}

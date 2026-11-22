import SwiftUI

/// The back pill ("‹ Recipes") and Edit pill overlaid at the top of the detail screen.
struct DetailPills: View {
    let onBack: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Recipes")
                        .typography(.pill)
                }
                .foregroundStyle(Palette.accent)
                .padding(.leading, 10)
                .padding(.trailing, 14)
                .frame(minHeight: 44)
                .background(Palette.card, in: Capsule())
            }
            .accessibilityLabel("Back to Recipes")

            Spacer()

            Button(action: onEdit) {
                Text("Edit")
                    .typography(.pillProminent)
                    .foregroundStyle(Palette.onAccent)
                    .padding(.horizontal, 20)
                    .frame(minHeight: 44)
                    .background(Palette.accent, in: Capsule())
            }
        }
        .buttonStyle(.plainLabel)
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }
}

#Preview("Light") {
    DetailPills(onBack: {}, onEdit: {})
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Palette.hero0)
}

#Preview("Dark") {
    DetailPills(onBack: {}, onEdit: {})
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Palette.hero0)
        .preferredColorScheme(.dark)
}

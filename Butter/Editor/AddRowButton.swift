import SwiftUI

/// The footer row of a list card: "Add Ingredient", "Add Step".
struct AddRowButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 20, weight: .medium))
                Text(title)
                    .typography(.button)
            }
            .foregroundStyle(Palette.accent)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plainLabel)
    }
}

#Preview("Light") {
    AddRowButton(title: "Add Ingredient", action: {})
        .card(cornerRadius: 14)
        .padding()
        .background(Palette.bg)
}

#Preview("Dark") {
    AddRowButton(title: "Add Step", action: {})
        .card(cornerRadius: 14)
        .padding()
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}

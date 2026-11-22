import SwiftUI

/// The outlined destructive button at the foot of the editor, Edit mode only.
struct DeleteRecipeButton: View {
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            Text("Delete Recipe")
                .typography(.destructive)
                .foregroundStyle(Palette.danger)
                .frame(maxWidth: .infinity, minHeight: 50)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Palette.dangerLine, lineWidth: 1)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plainLabel)
    }
}

#Preview("Light") {
    DeleteRecipeButton(action: {})
        .padding(16)
        .background(Palette.bg)
}

#Preview("Dark") {
    DeleteRecipeButton(action: {})
        .padding(16)
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}

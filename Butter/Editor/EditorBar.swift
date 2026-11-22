import SwiftUI

/// Cancel, the serif sheet title, and Save (disabled until there is a title).
struct EditorBar: View {
    let title: String
    let canSave: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .typography(.editorTitle)
                .foregroundStyle(Palette.ink)
                .accessibilityAddTraits(.isHeader)
            HStack {
                Button("Cancel", action: onCancel)
                    .typography(.navAction)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save", action: onSave)
                    .typography(.navActionProminent)
                    .disabled(!canSave)
            }
            .foregroundStyle(Palette.accent)
            .buttonStyle(.plainLabel)
            .frame(minHeight: 44)
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Palette.bg)
        .overlay(alignment: .bottom) { CardDivider() }
    }
}

#Preview("Light") {
    VStack(spacing: 0) {
        EditorBar(title: "New Recipe", canSave: false, onCancel: {}, onSave: {})
        EditorBar(title: "Edit Recipe", canSave: true, onCancel: {}, onSave: {})
    }
    .background(Palette.bg)
}

#Preview("Dark") {
    VStack(spacing: 0) {
        EditorBar(title: "New Recipe", canSave: false, onCancel: {}, onSave: {})
        EditorBar(title: "Edit Recipe", canSave: true, onCancel: {}, onSave: {})
    }
    .background(Palette.bg)
    .preferredColorScheme(.dark)
}

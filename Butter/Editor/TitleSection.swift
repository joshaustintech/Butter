import SwiftUI

/// The one required field.
struct TitleSection: View {
    @Binding var title: String

    var body: some View {
        EditorSection(title: "Title", requirement: .required) {
            TextField("Title", text: $title, prompt: Text("Recipe name").foregroundStyle(Palette.muted))
                .typography(.titleField)
                .foregroundStyle(Palette.ink)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .padding(.horizontal, 16)
                .frame(minHeight: 52)
                .card(cornerRadius: 14)
        }
    }
}

#Preview("Light") {
    @Previewable @State var title = ""
    TitleSection(title: $title)
        .padding(16)
        .background(Palette.bg)
}

#Preview("Dark") {
    @Previewable @State var title = "Rhubarb Galette"
    TitleSection(title: $title)
        .padding(16)
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}

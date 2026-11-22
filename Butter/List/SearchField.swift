import SwiftUI

/// The list's title filter.
struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Palette.muted)
                .accessibilityHidden(true)
            TextField(
                "Search recipes",
                text: $text,
                prompt: Text("Search recipes").foregroundStyle(Palette.muted)
            )
            .typography(.search)
            .foregroundStyle(Palette.ink)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 44)
        .background(Palette.fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview("Light") {
    @Previewable @State var text = ""
    SearchField(text: $text)
        .padding()
        .background(Palette.bg)
}

#Preview("Dark") {
    @Previewable @State var text = "Galette"
    SearchField(text: $text)
        .padding()
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}

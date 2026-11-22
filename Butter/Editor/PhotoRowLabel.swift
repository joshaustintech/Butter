import SwiftUI

/// The dashed-border row inside the photo picker: preview tile, "Add Photo"
/// and the caption explaining the monogram fallback.
struct PhotoRowLabel: View {
    let letter: String?
    let photo: Data?

    var body: some View {
        HStack(spacing: 14) {
            PhotoPreviewTile(letter: letter, photo: photo)
            VStack(alignment: .leading, spacing: 2) {
                Text(photo == nil ? "Add Photo" : "Change Photo")
                    .typography(.button)
                    .foregroundStyle(Palette.accent)
                Text("Without one, the title’s first letter is shown.")
                    .typography(.caption)
                    .foregroundStyle(Palette.muted)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Palette.fill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Palette.leaf, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        }
        .contentShape(Rectangle())
    }
}

#Preview("Light") {
    PhotoRowLabel(letter: "R", photo: nil)
        .padding(16)
        .background(Palette.bg)
}

#Preview("Dark") {
    PhotoRowLabel(letter: nil, photo: nil)
        .padding(16)
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}

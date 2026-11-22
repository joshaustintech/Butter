import SwiftUI

/// The 72 pt preview at the start of the photo row: the picked photo,
/// or a small monogram on `hero0`.
struct PhotoPreviewTile: View {
    let letter: String?
    let photo: Data?

    var body: some View {
        ZStack {
            Rectangle().fill(Palette.hero0)
            if let photo = PhotoImage(data: photo) {
                photo
            } else {
                MonogramDisc(letter: letter, size: .preview)
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityHidden(true)
    }
}

#Preview("Light") {
    HStack {
        PhotoPreviewTile(letter: "R", photo: nil)
        PhotoPreviewTile(letter: nil, photo: nil)
    }
    .padding()
    .background(Palette.fill)
}

#Preview("Dark") {
    HStack {
        PhotoPreviewTile(letter: "R", photo: nil)
        PhotoPreviewTile(letter: nil, photo: nil)
    }
    .padding()
    .background(Palette.fill)
    .preferredColorScheme(.dark)
}

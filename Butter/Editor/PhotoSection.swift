import PhotosUI
import SwiftUI

/// The dashed photo row. Until a photo is picked, a small monogram of the
/// current title previews what the recipe will show instead.
struct PhotoSection: View {
    @Binding var photo: Data?
    let title: String
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        EditorSection(title: "Photo") {
            let letter = Monogram.letter(in: title)
            let current = photo
            PhotosPicker(selection: $pickerItem, matching: .images) {
                PhotoRowLabel(letter: letter, photo: current)
            }
            .buttonStyle(.plainLabel)
            .contextMenu {
                if photo != nil {
                    Button("Remove Photo", systemImage: "minus.circle", role: .destructive) { photo = nil }
                }
            }
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let prepared = PhotoData.prepared(data) {
                    photo = prepared
                }
                pickerItem = nil
            }
        }
    }
}

#Preview("Light") {
    @Previewable @State var photo: Data?
    PhotoSection(photo: $photo, title: "Rhubarb Galette")
        .padding(16)
        .background(Palette.bg)
}

#Preview("Dark") {
    @Previewable @State var photo: Data?
    PhotoSection(photo: $photo, title: "")
        .padding(16)
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}

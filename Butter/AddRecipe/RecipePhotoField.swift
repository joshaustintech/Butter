import PhotosUI
import SwiftUI
import UIKit

/// Chooses an optional photo of the dish with the system photo picker
/// (no photo library permission needed). The photo can be removed again.
struct RecipePhotoField: View {
    @Binding var photo: Data?
    @State private var selection: PhotosPickerItem?
    @State private var loading: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: ButterSpacing.xs) {
            FieldHeader(label: "Photo")
            if let photo, let image = UIImage(data: photo) {
                RecipePhoto(image: image)
                Button("Remove photo", role: .destructive) {
                    loading?.cancel()
                    self.photo = nil
                    selection = nil
                }
                .buttonStyle(.butterSecondary)
            } else {
                PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
                    Label("Add photo", systemImage: "photo")
                }
                .buttonStyle(.butterSecondary)
            }
        }
        .onChange(of: selection) { _, item in
            loading?.cancel()
            guard let item else { return }
            loading = Task {
                // A failed or cancelled load keeps the photo already shown.
                guard let data = try? await item.loadTransferable(type: Data.self),
                      !Task.isCancelled else { return }
                photo = data
            }
        }
    }
}

private let previewPhoto = UIImage(systemName: "fork.knife")?.pngData()

#Preview("Light, empty") {
    @Previewable @State var photo: Data?
    RecipePhotoField(photo: $photo)
        .padding(ButterSpacing.md)
        .background(Color.butterBackground)
        .preferredColorScheme(.light)
}

#Preview("Dark, empty") {
    @Previewable @State var photo: Data?
    RecipePhotoField(photo: $photo)
        .padding(ButterSpacing.md)
        .background(Color.butterBackground)
        .preferredColorScheme(.dark)
}

#Preview("Light, with photo") {
    @Previewable @State var photo: Data? = previewPhoto
    RecipePhotoField(photo: $photo)
        .padding(ButterSpacing.md)
        .background(Color.butterBackground)
        .preferredColorScheme(.light)
}

#Preview("Dark, with photo") {
    @Previewable @State var photo: Data? = previewPhoto
    RecipePhotoField(photo: $photo)
        .padding(ButterSpacing.md)
        .background(Color.butterBackground)
        .preferredColorScheme(.dark)
}

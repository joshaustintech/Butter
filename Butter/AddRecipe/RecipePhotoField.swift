import PhotosUI
import SwiftUI
import UIKit

/// Chooses an optional photo of the dish with the system photo picker
/// (no photo library permission needed). The photo can be removed again.
struct RecipePhotoField: View {
    @Binding var photo: Data?
    @State private var selection: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: ButterSpacing.xs) {
            Text("Photo")
                .font(.headline)
                .foregroundStyle(Color.butterLabel)
            if let photo, let image = UIImage(data: photo) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: ButterRadius.medium, style: .continuous))
                    .accessibilityLabel("Photo of the dish")
                Button("Remove photo", role: .destructive) {
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
            guard let item else { return }
            Task { photo = try? await item.loadTransferable(type: Data.self) }
        }
    }
}

#Preview("Light, empty") {
    @Previewable @State var photo: Data?
    RecipePhotoField(photo: $photo)
        .padding(ButterSpacing.md)
        .background(Color.butterBackground)
        .preferredColorScheme(.light)
}

#Preview("Dark, with photo") {
    @Previewable @State var photo: Data? = UIImage(systemName: "fork.knife")?.pngData()
    RecipePhotoField(photo: $photo)
        .padding(ButterSpacing.md)
        .background(Color.butterBackground)
        .preferredColorScheme(.dark)
}

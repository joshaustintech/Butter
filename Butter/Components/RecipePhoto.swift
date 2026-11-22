import SwiftUI
import UIKit

/// A photo of the dish, filled to a 4:3 frame with rounded corners.
struct RecipePhoto: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .aspectRatio(4 / 3, contentMode: .fit)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: ButterRadius.medium, style: .continuous))
            .accessibilityLabel("Photo of the dish")
    }
}

private let previewImage = UIImage(systemName: "fork.knife") ?? UIImage()

#Preview("Light") {
    RecipePhoto(image: previewImage)
        .padding(ButterSpacing.md)
        .background(Color.butterBackground)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    RecipePhoto(image: previewImage)
        .padding(ButterSpacing.md)
        .background(Color.butterBackground)
        .preferredColorScheme(.dark)
}

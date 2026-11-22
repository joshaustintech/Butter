import SwiftUI
import UIKit

/// A stored photo, cropped to fill whatever frame it is given.
struct PhotoImage: View {
    let image: UIImage

    init?(data: Data?) {
        guard let image = data.flatMap(UIImage.init(data:)) else { return nil }
        self.image = image
    }

    var body: some View {
        Color.clear
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .accessibilityHidden(true)
    }
}

#if DEBUG
private let sampleData = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 200)).pngData { context in
    UIColor(named: "tintButter")?.setFill()
    context.fill(CGRect(x: 0, y: 0, width: 300, height: 200))
    UIColor(named: "tintRose")?.setFill()
    context.cgContext.fillEllipse(in: CGRect(x: 90, y: 40, width: 120, height: 120))
}

#Preview("Light") {
    PhotoImage(data: sampleData)
        .frame(width: 200, height: 200)
}

#Preview("Dark") {
    PhotoImage(data: sampleData)
        .frame(width: 200, height: 200)
        .preferredColorScheme(.dark)
}
#endif

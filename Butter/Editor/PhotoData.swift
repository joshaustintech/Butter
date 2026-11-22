import UIKit

/// Prepares a picked photo for storage: decoded, shrunk so its longest side
/// is at most `longestSide` pixels, and re-encoded as JPEG.
enum PhotoData {
    static let longestSide: CGFloat = 1600

    static func prepared(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let pixels = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        let shrink = min(1, longestSide / max(pixels.width, pixels.height))
        let target = CGSize(width: (pixels.width * shrink).rounded(), height: (pixels.height * shrink).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).jpegData(withCompressionQuality: 0.85) { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

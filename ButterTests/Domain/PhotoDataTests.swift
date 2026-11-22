import Testing
import UIKit
@testable import Butter

struct PhotoDataTests {
    private func jpeg(width: CGFloat, height: CGFloat) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
            .jpegData(withCompressionQuality: 0.9) { context in
                UIColor.orange.setFill()
                context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            }
    }

    @Test func shrinksLargePhotosToTheLongestSideLimit() throws {
        let prepared = try #require(PhotoData.prepared(jpeg(width: 4000, height: 3000)))
        let image = try #require(UIImage(data: prepared))
        #expect(max(image.size.width * image.scale, image.size.height * image.scale) <= PhotoData.longestSide)
        let aspect = image.size.width / image.size.height
        #expect(abs(aspect - 4.0 / 3.0) < 0.01)
    }

    @Test func leavesSmallPhotosAtTheirSize() throws {
        let prepared = try #require(PhotoData.prepared(jpeg(width: 300, height: 200)))
        let image = try #require(UIImage(data: prepared))
        #expect(image.size.width * image.scale == 300)
    }

    @Test func rejectsDataThatIsNotAnImage() {
        #expect(PhotoData.prepared(Data("not a photo".utf8)) == nil)
    }
}

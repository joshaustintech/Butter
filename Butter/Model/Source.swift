import Foundation
import SwiftData

/// Where a Recipe came from: a webpage, or a photographed page.
@Model
final class Source {
    enum Kind: String, Codable, Sendable {
        case webpage
        case photographedPage
    }

    private var kindRawValue: String = Kind.webpage.rawValue
    /// The webpage address, when the Source is a webpage.
    var url: URL?
    /// The photo of the page, when the Source is a photographed page.
    @Attribute(.externalStorage) var pageImage: Data?
    var recipe: Recipe?

    var kind: Kind {
        get { Kind(rawValue: kindRawValue) ?? .webpage }
        set { kindRawValue = newValue.rawValue }
    }

    /// The webpage address, only when the Source is a webpage.
    var webpageURL: URL? { kind == .webpage ? url : nil }

    init(webpage url: URL?) {
        self.kindRawValue = Kind.webpage.rawValue
        self.url = url
    }

    init(photographedPage image: Data?) {
        self.kindRawValue = Kind.photographedPage.rawValue
        self.pageImage = image
    }
}

import Foundation
import Testing
@testable import Butter

struct SourceTests {
    @Test func webpageSourceHasWebpageURL() {
        let url = URL(string: "https://example.com/pancakes")!
        #expect(Source(webpage: url).webpageURL == url)
    }

    @Test func photographedPageHasNoWebpageURL() {
        let source = Source(photographedPage: Data([1]))
        source.url = URL(string: "https://example.com")
        #expect(source.webpageURL == nil)
    }
}

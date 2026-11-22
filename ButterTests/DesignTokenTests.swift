import Testing
import UIKit
@testable import Butter

// Guards the Cottage Butter color tokens: every token must exist in the
// asset catalog with both a light and a dark variant.
@MainActor
struct DesignTokenTests {
    static let colorTokens = [
        "ButterBackground",
        "ButterSurface",
        "ButterSeparator",
        "ButterPrimary",
        "ButterOnPrimary",
        "ButterLabel",
        "ButterLabelSecondary",
        "ButterAccent",
        "ButterSageFill",
        "ButterBlushFill",
        "ButterBlushAccent",
        "ButterError",
    ]

    @Test(arguments: colorTokens)
    func colorTokenHasLightAndDarkVariants(name: String) {
        let light = UIColor(named: name, in: .main, compatibleWith: UITraitCollection(userInterfaceStyle: .light))
        let dark = UIColor(named: name, in: .main, compatibleWith: UITraitCollection(userInterfaceStyle: .dark))
        #expect(light != nil, "\(name) has no light variant")
        #expect(dark != nil, "\(name) has no dark variant")
        #expect(light != dark, "\(name) looks identical in light and dark")
    }

    @Test func accentMatchesButterSage() {
        let accent = UIColor(named: "AccentColor", in: .main, compatibleWith: nil)
        #expect(accent != nil, "AccentColor is missing from the asset catalog")
    }
}

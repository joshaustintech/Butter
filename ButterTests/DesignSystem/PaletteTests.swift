import SwiftUI
import Testing
import UIKit
@testable import Butter

struct PaletteTests {
    /// The colour table from HANDOFF.md, verbatim: (light, dark).
    static let handoff: [Palette: (light: String, dark: String)] = [
        .bg: ("#F5EEDF", "#1F1A15"),
        .card: ("#FBF7EC", "#2A231C"),
        .fill: ("#E9DFCB", "#352C23"),
        .line: ("#E2D6BD", "#433829"),
        .ink: ("#3B2E25", "#F1E8D6"),
        .muted: ("#6B5A4C", "#BBAC95"),
        .accent: ("#4F6340", "#A9C08F"),
        .onAccent: ("#FBF7EC", "#1F1A15"),
        .star: ("#B8862B", "#E0B352"),
        .leaf: ("#8FA37A", "#6F8A5A"),
        .danger: ("#9A4A46", "#E59A94"),
        .dangerLine: ("#D2B0AB", "#6B403C"),
        .tintSage: ("#D5DFC4", "#3B4630"),
        .tintButter: ("#F0DDA0", "#4D4222"),
        .tintRose: ("#EBC9C4", "#4F3030"),
        .hero0: ("#EBC9C4", "#33241F"),
        .hero1: ("#F4DDD8", "#3E2B27"),
        .chevron: ("#8A7868", "#8F806C"),
    ]

    @Test func everyHandoffTokenIsInThePalette() {
        #expect(Set(Palette.allCases) == Set(Self.handoff.keys))
    }

    @Test(arguments: Palette.allCases)
    func lightAppearanceMatchesTheHandoff(_ token: Palette) throws {
        let expected = try #require(Self.handoff[token]).light
        #expect(try hex(of: token, in: .light) == expected)
    }

    @Test(arguments: Palette.allCases)
    func darkAppearanceMatchesTheHandoff(_ token: Palette) throws {
        let expected = try #require(Self.handoff[token]).dark
        #expect(try hex(of: token, in: .dark) == expected)
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func theAppTintIsTheAccentToken(_ scheme: ColorScheme) throws {
        let style: UIUserInterfaceStyle = scheme == .dark ? .dark : .light
        let tint = try #require(UIColor(named: "AccentColor", in: .main, compatibleWith: nil))
        #expect(Self.hex(tint.resolvedColor(with: UITraitCollection(userInterfaceStyle: style)))
            == (try hex(of: .accent, in: style)))
    }

    @Test func tileTintsMapToTheirTokens() {
        #expect(TileTint.allCases.map(\.palette) == [.tintSage, .tintButter, .tintRose])
    }

    @Test func detailTilesUseSageButterRose() {
        #expect(DetailKind.allCases.map(\.tint) == [.sage, .butter, .rose])
    }

    private func hex(of token: Palette, in style: UIUserInterfaceStyle) throws -> String {
        let color = try #require(UIColor(named: token.rawValue, in: .main, compatibleWith: nil))
        return Self.hex(color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style)))
    }

    private static func hex(_ color: UIColor) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
    }
}

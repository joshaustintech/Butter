import SwiftUI

// Cottage Butter design tokens for SwiftUI.
// Source of truth: docs/design/tokens.json. Colors live in Colors.xcassets,
// so light and dark appearance is automatic. Keep all three in sync.

// MARK: - Color

extension Color {
    // Ground and surfaces
    static let butterBackground = Color("ButterBackground")
    static let butterSurface = Color("ButterSurface")
    static let butterSeparator = Color("ButterSeparator")

    // Fills
    static let butterPrimary = Color("ButterPrimary")          // butter yellow fill, never text
    static let butterSageFill = Color("ButterSageFill")
    static let butterBlushFill = Color("ButterBlushFill")
    static let butterBlushAccent = Color("ButterBlushAccent")  // decoration only

    // Text and tint
    static let butterLabel = Color("ButterLabel")
    static let butterLabelSecondary = Color("ButterLabelSecondary")
    static let butterOnPrimary = Color("ButterOnPrimary")      // text on butterPrimary
    static let butterAccent = Color("ButterAccent")            // sage, app tint and links

    // Status
    static let butterError = Color("ButterError")
}

// MARK: - Spacing (4 pt grid)

enum ButterSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40
}

// MARK: - Corner radius (use with style: .continuous)

enum ButterRadius {
    static let small: CGFloat = 12
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
}

// MARK: - Typography
// Text styles scale with Dynamic Type. Do not pass fixed point sizes.

extension Font {
    /// New York (system serif) for brand moments: titles, greetings, empty states.
    static func butterDisplay(_ style: Font.TextStyle = .largeTitle) -> Font {
        .system(style, design: .serif).weight(.semibold)
    }
}

// MARK: - Tint

extension View {
    /// Applies the Cottage Butter tint (sage) to the view tree.
    func butterTheme() -> some View {
        tint(.butterAccent)
    }
}

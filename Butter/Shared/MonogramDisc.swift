import SwiftUI

/// The title's first letter in a `hero1` disc with a double `accent` ring.
/// Stands in wherever a recipe has no photo.
struct MonogramDisc: View {
    enum Size {
        /// Detail hero: 124 pt disc, 2 pt ring, inner ring inset 6 pt.
        case hero
        /// Editor photo preview: 52 pt disc, 1.5 pt ring, inner ring inset 3 pt.
        case preview

        var diameter: CGFloat { self == .hero ? 124 : 52 }
        var ringWidth: CGFloat { self == .hero ? 2 : 1.5 }
        var innerRingInset: CGFloat { self == .hero ? 6 : 3 }
        var typography: Typography { self == .hero ? .heroMonogram : .previewMonogram }
    }

    /// `nil` while there is no title yet: the disc shows empty.
    let letter: String?
    let size: Size

    var body: some View {
        ZStack {
            Circle().fill(Palette.hero1)
            Circle().strokeBorder(Palette.accent, lineWidth: size.ringWidth)
            Circle()
                .strokeBorder(Palette.accent, lineWidth: 1)
                .padding(size.ringWidth + size.innerRingInset)
            if let letter {
                Text(letter)
                    .typography(size.typography)
                    .foregroundStyle(Palette.ink)
            }
        }
        .frame(width: size.diameter, height: size.diameter)
        .accessibilityHidden(true)
    }
}

#Preview("Light") {
    HStack(spacing: 24) {
        MonogramDisc(letter: "R", size: .hero)
        MonogramDisc(letter: "R", size: .preview)
        MonogramDisc(letter: nil, size: .preview)
    }
    .padding()
    .background(Palette.hero0)
}

#Preview("Dark") {
    HStack(spacing: 24) {
        MonogramDisc(letter: "R", size: .hero)
        MonogramDisc(letter: "R", size: .preview)
        MonogramDisc(letter: nil, size: .preview)
    }
    .padding()
    .background(Palette.hero0)
    .preferredColorScheme(.dark)
}

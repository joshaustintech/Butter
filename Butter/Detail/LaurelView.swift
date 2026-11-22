import SwiftUI

/// Sixteen small `leaf` ellipses arcing around the hero's monogram disc.
struct LaurelView: View {
    let radius: CGFloat
    private let leafSize = CGSize(width: 22, height: 9)

    var body: some View {
        ZStack {
            ForEach(Array(Laurel.leaves(radius: radius).enumerated()), id: \.offset) { _, leaf in
                Ellipse()
                    .fill(Palette.leaf)
                    .frame(width: leafSize.width, height: leafSize.height)
                    .rotationEffect(leaf.rotation)
                    .offset(x: leaf.center.x, y: leaf.center.y)
            }
        }
        .frame(width: (radius + leafSize.width) * 2, height: (radius + leafSize.width) * 2)
        .accessibilityHidden(true)
    }
}

#Preview("Light") {
    LaurelView(radius: 80)
        .padding()
        .background(Palette.hero0)
}

#Preview("Dark") {
    LaurelView(radius: 80)
        .padding()
        .background(Palette.hero0)
        .preferredColorScheme(.dark)
}

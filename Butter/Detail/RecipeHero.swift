import SwiftUI

/// The 240 pt full-width hero: the photo, or the laurelled monogram when there is none.
struct RecipeHero: View {
    static let height: CGFloat = 240

    let letter: String?
    let photo: Data?

    var body: some View {
        Group {
            if let photo = PhotoImage(data: photo) {
                photo
            } else {
                ZStack {
                    Rectangle().fill(Palette.hero0)
                    ZStack {
                        LaurelView(radius: 80)
                        MonogramDisc(letter: letter, size: .hero)
                    }
                    // The status bar covers the top of the hero, so the motif sits a little low.
                    .padding(.top, 40)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.height)
        .clipped()
        .accessibilityHidden(true)
    }
}

#Preview("Light") {
    RecipeHero(letter: "R", photo: nil)
        .frame(maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
        .background(Palette.bg)
}

#Preview("Dark") {
    RecipeHero(letter: "R", photo: nil)
        .frame(maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}

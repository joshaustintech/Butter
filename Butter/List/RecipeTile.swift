import SwiftUI

/// The 60 pt tile at the start of a row: the photo if there is one,
/// otherwise the title's first letter on the row's tint.
struct RecipeTile: View {
    let letter: String?
    let photo: Data?
    let tint: TileTint

    var body: some View {
        ZStack {
            Rectangle().fill(tint.palette)
            if let photo = PhotoImage(data: photo) {
                photo
            } else if let letter {
                Text(letter)
                    .typography(.tileMonogram)
                    .foregroundStyle(Palette.ink)
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityHidden(true)
    }
}

#Preview("Light") {
    HStack {
        ForEach(TileTint.allCases, id: \.self) { tint in
            RecipeTile(letter: "R", photo: nil, tint: tint)
        }
    }
    .padding()
    .background(Palette.card)
}

#Preview("Dark") {
    HStack {
        ForEach(TileTint.allCases, id: \.self) { tint in
            RecipeTile(letter: "R", photo: nil, tint: tint)
        }
    }
    .padding()
    .background(Palette.card)
    .preferredColorScheme(.dark)
}

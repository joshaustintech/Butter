import SwiftUI

/// A detail-screen section: a serif heading above its content.
struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .typography(.sectionTitle)
                .foregroundStyle(Palette.ink)
                .accessibilityAddTraits(.isHeader)
            content
        }
    }
}

#Preview("Light") {
    DetailSection(title: "My Review") {
        Text("Section content").typography(.body)
    }
    .padding()
    .background(Palette.bg)
}

#Preview("Dark") {
    DetailSection(title: "My Review") {
        Text("Section content").typography(.body)
    }
    .padding()
    .background(Palette.bg)
    .preferredColorScheme(.dark)
}

import SwiftUI

/// The headline label above a form field or a detail section.
struct FieldHeader: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.headline)
            .foregroundStyle(Color.butterLabel)
    }
}

#Preview("Light") {
    FieldHeader(label: "Ingredients")
        .padding(ButterSpacing.md)
        .background(Color.butterBackground)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FieldHeader(label: "Ingredients")
        .padding(ButterSpacing.md)
        .background(Color.butterBackground)
        .preferredColorScheme(.dark)
}

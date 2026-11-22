import SwiftUI

/// Free-form notes on how it turned out.
struct ReviewNotesSection: View {
    @Binding var notes: String

    var body: some View {
        EditorSection(title: "Review Notes") {
            TextField(
                "Review Notes",
                text: $notes,
                prompt: Text("How did it turn out?").foregroundStyle(Palette.muted),
                axis: .vertical
            )
            .lineLimit(4...)
            .typography(.body)
            .foregroundStyle(Palette.ink)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .card(cornerRadius: 14)
        }
    }
}

#Preview("Light") {
    @Previewable @State var notes = ""
    ReviewNotesSection(notes: $notes)
        .padding(16)
        .background(Palette.bg)
}

#Preview("Dark") {
    @Previewable @State var notes = "Tart and sweet in just the right measure."
    ReviewNotesSection(notes: $notes)
        .padding(16)
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}

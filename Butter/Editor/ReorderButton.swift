import SwiftUI

/// "Reorder", which becomes "Done" while the section is being reordered.
struct ReorderButton: View {
    @Binding var isReordering: Bool

    var body: some View {
        Button(isReordering ? "Done" : "Reorder") {
            isReordering.toggle()
        }
        .typography(.button)
        .foregroundStyle(Palette.accent)
        .buttonStyle(.plainLabel)
        .frame(minHeight: 44)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .padding(.vertical, -6)
    }
}

#Preview("Light") {
    @Previewable @State var isReordering = false
    ReorderButton(isReordering: $isReordering)
        .padding()
        .background(Palette.bg)
}

#Preview("Dark") {
    @Previewable @State var isReordering = true
    ReorderButton(isReordering: $isReordering)
        .padding()
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}

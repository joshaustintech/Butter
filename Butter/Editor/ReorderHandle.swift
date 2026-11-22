import SwiftUI

/// The three-line grip shown on rows while reordering. Dragging is handled by
/// the row container; VoiceOver users move rows with the Move Up / Move Down actions.
struct ReorderHandle: View {
    let name: String
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    var body: some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(Palette.muted)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .accessibilityElement()
            .accessibilityLabel("Reorder \(name)")
            .accessibilityHint("Drag up or down to move.")
            .accessibilityActions {
                if canMoveUp { Button("Move Up", action: onMoveUp) }
                if canMoveDown { Button("Move Down", action: onMoveDown) }
            }
    }
}

#Preview("Light") {
    ReorderHandle(name: "Prep time", canMoveUp: false, canMoveDown: true, onMoveUp: {}, onMoveDown: {})
        .padding()
        .background(Palette.card)
}

#Preview("Dark") {
    ReorderHandle(name: "Prep time", canMoveUp: false, canMoveDown: true, onMoveUp: {}, onMoveDown: {})
        .padding()
        .background(Palette.card)
        .preferredColorScheme(.dark)
}

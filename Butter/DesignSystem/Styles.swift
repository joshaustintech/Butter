import SwiftUI

extension View {
    /// A grouped card: card background, 1 pt `line` border, continuous corners.
    func card(cornerRadius: CGFloat = 16) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return background(Palette.card, in: shape)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Palette.line, lineWidth: 1))
    }
}

/// Buttons drawn entirely by their label: dimmed while pressed, faded when disabled.
struct PlainLabelButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(isEnabled ? (configuration.isPressed ? 0.6 : 1) : 0.35)
    }
}

/// Rows in a card: tinted `fill` while pressed.
struct CardRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Palette.fill : Palette.card)
    }
}

extension ButtonStyle where Self == PlainLabelButtonStyle {
    static var plainLabel: PlainLabelButtonStyle { PlainLabelButtonStyle() }
}

extension ButtonStyle where Self == CardRowButtonStyle {
    static var cardRow: CardRowButtonStyle { CardRowButtonStyle() }
}

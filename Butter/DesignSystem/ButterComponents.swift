import SwiftUI

// MARK: - Buttons (tap target at least 44 pt)

struct ButterPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.butterOnPrimary)
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal, ButterSpacing.lg)
            .background(Color.butterPrimary, in: Capsule())
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

struct ButterSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.butterAccent)
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal, ButterSpacing.lg)
            .overlay(Capsule().strokeBorder(Color.butterAccent, lineWidth: 1.5))
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ButterPrimaryButtonStyle {
    static var butterPrimary: ButterPrimaryButtonStyle { .init() }
}

extension ButtonStyle where Self == ButterSecondaryButtonStyle {
    static var butterSecondary: ButterSecondaryButtonStyle { .init() }
}

// MARK: - Card surface

struct ButterCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(ButterSpacing.md)
            .background(
                Color.butterSurface,
                in: RoundedRectangle(cornerRadius: ButterRadius.medium, style: .continuous)
            )
    }
}

extension View {
    /// Wraps content in a Cottage Butter surface card.
    func butterCard() -> some View {
        modifier(ButterCardModifier())
    }
}

// MARK: - Chip (single-select filter)

struct ButterChip: View {
    let title: String
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.butterOnPrimary : Color.butterLabel)
                .padding(.horizontal, ButterSpacing.md)
                .frame(minHeight: 44)
                .background(isSelected ? Color.butterPrimary : Color.butterSurface, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.butterSeparator, lineWidth: isSelected ? 0 : 1))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

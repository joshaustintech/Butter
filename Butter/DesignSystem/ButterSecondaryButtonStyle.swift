import SwiftUI

// Secondary button (tap target at least 44 pt).

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

extension ButtonStyle where Self == ButterSecondaryButtonStyle {
    static var butterSecondary: ButterSecondaryButtonStyle { .init() }
}

/// Preview-only example showing the style enabled and disabled.
private struct ButterSecondaryButtonExample: View {
    var body: some View {
        VStack(spacing: ButterSpacing.md) {
            Button("Maybe later") {}
                .buttonStyle(.butterSecondary)
            Button("Maybe later") {}
                .buttonStyle(.butterSecondary)
                .disabled(true)
        }
        .padding(ButterSpacing.lg)
        .background(Color.butterBackground)
    }
}

#Preview("Light") {
    ButterSecondaryButtonExample()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ButterSecondaryButtonExample()
        .preferredColorScheme(.dark)
}

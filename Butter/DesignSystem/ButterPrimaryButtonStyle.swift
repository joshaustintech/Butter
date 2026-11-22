import SwiftUI

// Primary button (tap target at least 44 pt).

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

extension ButtonStyle where Self == ButterPrimaryButtonStyle {
    static var butterPrimary: ButterPrimaryButtonStyle { .init() }
}

/// Preview-only example showing the style enabled and disabled.
struct ButterPrimaryButtonExample: View {
    var body: some View {
        VStack(spacing: ButterSpacing.md) {
            Button("Save recipe") {}
                .buttonStyle(.butterPrimary)
            Button("Save recipe") {}
                .buttonStyle(.butterPrimary)
                .disabled(true)
        }
        .padding(ButterSpacing.lg)
        .background(Color.butterBackground)
    }
}

#Preview("Light") {
    ButterPrimaryButtonExample()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ButterPrimaryButtonExample()
        .preferredColorScheme(.dark)
}

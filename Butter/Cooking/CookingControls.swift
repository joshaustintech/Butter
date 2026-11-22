import SwiftUI

/// Next (or Finish), Back and Repeat buttons.
struct CookingControls: View {
    let isFirst: Bool
    let isLast: Bool
    var onNext: () -> Void = {}
    var onBack: () -> Void = {}
    var onRepeat: () -> Void = {}

    var body: some View {
        VStack(spacing: ButterSpacing.sm) {
            Button(isLast ? "Finish" : "Next",
                   systemImage: isLast ? "checkmark" : "forward.fill", action: onNext)
                .buttonStyle(.butterPrimary)

            HStack(spacing: ButterSpacing.sm) {
                Button("Back", systemImage: "backward.fill", action: onBack)
                    .buttonStyle(.butterSecondary)
                    .disabled(isFirst)
                Button("Repeat", systemImage: "arrow.counterclockwise", action: onRepeat)
                    .buttonStyle(.butterSecondary)
            }
        }
    }
}

#Preview("Light") {
    CookingControls(isFirst: false, isLast: false)
        .padding(ButterSpacing.xl)
        .background(Color.butterBackground)
        .preferredColorScheme(.light)
}

#Preview("Dark, first Step") {
    CookingControls(isFirst: true, isLast: false)
        .padding(ButterSpacing.xl)
        .background(Color.butterBackground)
        .preferredColorScheme(.dark)
}

#Preview("Dark, last Step") {
    CookingControls(isFirst: false, isLast: true)
        .padding(ButterSpacing.xl)
        .background(Color.butterBackground)
        .preferredColorScheme(.dark)
}

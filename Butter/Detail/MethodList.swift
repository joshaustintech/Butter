import SwiftUI

/// The numbered method: an `accent` number disc beside each step.
struct MethodList: View {
    let steps: [NonBlankText]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 14) {
                    StepNumberBadge(number: index + 1, size: .detail)
                    Text(step.value)
                        .typography(.body)
                        .lineSpacing(Typography.body.lineSpacing(lineHeight: 1.5))
                        .foregroundStyle(Palette.ink)
                        .padding(.top, 3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

#if DEBUG
#Preview("Light") {
    MethodList(steps: PreviewSamples.galette.steps)
        .padding(20)
        .background(Palette.bg)
}

#Preview("Dark") {
    MethodList(steps: PreviewSamples.galette.steps)
        .padding(20)
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}
#endif

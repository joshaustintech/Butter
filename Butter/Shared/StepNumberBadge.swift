import SwiftUI

/// A step's number in an `accent` circle.
struct StepNumberBadge: View {
    enum Size {
        /// Detail Method list: 32 pt circle, serif bold 19.
        case detail
        /// Editor Method rows: 28 pt circle, serif bold 17.
        case editor

        var diameter: CGFloat { self == .detail ? 32 : 28 }
        var typography: Typography { self == .detail ? .stepNumber : .stepBadge }
    }

    let number: Int
    let size: Size

    var body: some View {
        Text(number, format: .number)
            .typography(size.typography)
            .foregroundStyle(Palette.onAccent)
            .frame(width: size.diameter, height: size.diameter)
            .background(Palette.accent, in: Circle())
            .accessibilityLabel("Step \(number)")
    }
}

#Preview("Light") {
    HStack {
        StepNumberBadge(number: 1, size: .detail)
        StepNumberBadge(number: 12, size: .editor)
    }
    .padding()
    .background(Palette.bg)
}

#Preview("Dark") {
    HStack {
        StepNumberBadge(number: 1, size: .detail)
        StepNumberBadge(number: 12, size: .editor)
    }
    .padding()
    .background(Palette.bg)
    .preferredColorScheme(.dark)
}

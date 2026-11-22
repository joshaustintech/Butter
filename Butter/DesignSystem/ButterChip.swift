import SwiftUI

// Chip (single-select filter).

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

/// Preview-only: one chip selected, one not.
private struct ButterChipExample: View {
    var body: some View {
        HStack(spacing: ButterSpacing.xs) {
            ButterChip(title: "Herbs", isSelected: true) {}
            ButterChip(title: "Blooms", isSelected: false) {}
        }
        .padding(ButterSpacing.lg)
        .background(Color.butterBackground)
    }
}

#Preview("Light") {
    ButterChipExample()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ButterChipExample()
        .preferredColorScheme(.dark)
}

import SwiftUI

/// The Latest | Name segmented control. The selected segment sits on a card
/// background, with a subtle shadow in light mode only.
struct SortControl: View {
    @Binding var selection: RecipeSort
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 4) {
            ForEach(RecipeSort.allCases) { sort in
                let isSelected = sort == selection
                Button {
                    selection = sort
                } label: {
                    Text(sort.label)
                        .typography(isSelected ? .segmentSelected : .segment)
                        .foregroundStyle(isSelected ? Palette.ink : Palette.muted)
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(Palette.card)
                                    .shadow(
                                        color: colorScheme == .light ? Palette.ink.color.opacity(0.18) : .clear,
                                        radius: 1, y: 1
                                    )
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Palette.fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sort recipes")
    }
}

#Preview("Light") {
    @Previewable @State var sort = RecipeSort.latest
    SortControl(selection: $sort)
        .padding()
        .background(Palette.bg)
}

#Preview("Dark") {
    @Previewable @State var sort = RecipeSort.name
    SortControl(selection: $sort)
        .padding()
        .background(Palette.bg)
        .preferredColorScheme(.dark)
}

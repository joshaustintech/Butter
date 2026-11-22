import SwiftUI

/// Equal-width Prep / Bake / Serves tiles, only for details that have a value.
struct StatTiles: View {
    let stats: [RecipeStat]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(stats) { stat in
                VStack(alignment: .leading, spacing: 2) {
                    Text(stat.kind.tileLabel)
                        .typography(.statLabel)
                        .foregroundStyle(Palette.muted)
                    Text(stat.text)
                        .typography(.statValue)
                        .foregroundStyle(Palette.ink)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(12)
                .background(stat.kind.tint.palette, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityElement(children: .combine)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#if DEBUG
#Preview("Light") {
    VStack(spacing: 16) {
        StatTiles(stats: PreviewSamples.galette.stats)
        StatTiles(stats: PreviewSamples.sandwich.stats)
    }
    .padding(20)
    .background(Palette.bg)
}

#Preview("Dark") {
    VStack(spacing: 16) {
        StatTiles(stats: PreviewSamples.galette.stats)
        StatTiles(stats: PreviewSamples.sandwich.stats)
    }
    .padding(20)
    .background(Palette.bg)
    .preferredColorScheme(.dark)
}
#endif

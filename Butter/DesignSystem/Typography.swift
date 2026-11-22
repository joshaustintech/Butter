import SwiftUI

/// Every text style in the design. Titles and headings are the system serif
/// (New York); everything else is SF Pro. Sizes scale with Dynamic Type
/// relative to `textStyle`; monograms and numbers inside fixed-size discs don't.
enum Typography: CaseIterable {
    // Recipes list
    case listTitle, listSubtitle, search, segment, segmentSelected, rowTitle, rowMeta, tileMonogram
    // Recipe detail
    case pill, pillProminent, heroMonogram, detailTitle, ratingLine, statLabel, statValue
    case sectionTitle, body, stepNumber, review
    // Editor
    case editorTitle, navAction, navActionProminent, fieldHeader, fieldTag, titleField
    case previewMonogram, button, caption, stepBadge, stepper, destructive

    var size: CGFloat {
        switch self {
        case .listTitle: 44
        case .listSubtitle, .ratingLine: 14
        case .search, .pill, .pillProminent, .body, .button: 16
        case .segment, .segmentSelected: 15
        case .rowTitle, .review: 21
        case .rowMeta, .fieldHeader, .caption: 13
        case .tileMonogram: 30
        case .heroMonogram: 72
        case .detailTitle: 38
        case .statLabel, .fieldTag: 12
        case .statValue: 22
        case .sectionTitle, .previewMonogram: 28
        case .stepNumber: 19
        case .editorTitle, .titleField, .stepper: 24
        case .navAction, .navActionProminent, .destructive, .stepBadge: 17
        }
    }

    var weight: Font.Weight {
        switch self {
        case .listTitle, .rowTitle, .tileMonogram, .heroMonogram, .detailTitle, .statValue,
             .sectionTitle, .stepNumber, .editorTitle, .titleField, .previewMonogram, .stepBadge:
            .bold
        case .segmentSelected, .pillProminent, .review, .navActionProminent, .fieldHeader,
             .button, .destructive:
            .semibold
        case .segment, .pill, .statLabel, .navAction, .stepper:
            .medium
        case .listSubtitle, .search, .rowMeta, .ratingLine, .body, .fieldTag, .caption:
            .regular
        }
    }

    var design: Font.Design {
        switch self {
        case .listTitle, .rowTitle, .tileMonogram, .heroMonogram, .detailTitle, .statValue,
             .sectionTitle, .stepNumber, .review, .editorTitle, .titleField, .previewMonogram, .stepBadge:
            .serif
        default:
            .default
        }
    }

    var isItalic: Bool {
        switch self {
        case .tileMonogram, .heroMonogram, .previewMonogram, .review: true
        default: false
        }
    }

    var isUppercased: Bool { self == .fieldHeader }

    /// The Dynamic Type style the size scales with; `nil` for text that
    /// sits inside a fixed-size shape.
    var textStyle: Font.TextStyle? {
        switch self {
        case .listTitle, .detailTitle: .largeTitle
        case .sectionTitle: .title
        case .statValue, .editorTitle, .titleField, .stepper: .title2
        case .rowTitle, .review: .title3
        case .navAction, .navActionProminent, .destructive: .body
        case .search, .pill, .pillProminent, .body, .button: .callout
        case .listSubtitle, .ratingLine, .segment, .segmentSelected: .subheadline
        case .rowMeta, .fieldHeader, .caption: .footnote
        case .statLabel, .fieldTag: .caption
        case .tileMonogram, .heroMonogram, .stepNumber, .previewMonogram, .stepBadge: nil
        }
    }

    /// Extra spacing between lines to reach `lineHeight` × the font size.
    func lineSpacing(lineHeight: CGFloat) -> CGFloat {
        size * (lineHeight - 1)
    }
}

extension View {
    /// Applies a design-system text style.
    func typography(_ style: Typography) -> some View {
        modifier(TypographyModifier(style: style))
    }
}

private struct TypographyModifier: ViewModifier {
    let style: Typography
    @ScaledMetric private var size: CGFloat

    init(style: Typography) {
        self.style = style
        _size = ScaledMetric(wrappedValue: style.size, relativeTo: style.textStyle ?? .body)
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: style.textStyle == nil ? style.size : size, weight: style.weight, design: style.design))
            .italic(style.isItalic)
            .textCase(style.isUppercased ? .uppercase : nil)
            .tracking(style.isUppercased ? style.size * 0.04 : 0)
    }
}

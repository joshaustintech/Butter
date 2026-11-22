import SwiftUI
import Testing
@testable import Butter

struct TypographyTests {
    struct Spec {
        let size: CGFloat
        let weight: Font.Weight
        let serif: Bool
        let italic: Bool
        let scales: Bool

        static func serif(_ size: CGFloat, _ weight: Font.Weight = .bold, italic: Bool = false, scales: Bool = true) -> Spec {
            Spec(size: size, weight: weight, serif: true, italic: italic, scales: scales)
        }

        static func sans(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Spec {
            Spec(size: size, weight: weight, serif: false, italic: false, scales: true)
        }
    }

    /// Every size and weight named in HANDOFF.md.
    static let handoff: [Typography: Spec] = [
        .listTitle: .serif(44),
        .listSubtitle: .sans(14),
        .search: .sans(16),
        .segment: .sans(15, .medium),
        .segmentSelected: .sans(15, .semibold),
        .rowTitle: .serif(21),
        .rowMeta: .sans(13),
        .tileMonogram: .serif(30, italic: true, scales: false),
        .pill: .sans(16, .medium),
        .pillProminent: .sans(16, .semibold),
        .heroMonogram: .serif(72, italic: true, scales: false),
        .detailTitle: .serif(38),
        .ratingLine: .sans(14),
        .statLabel: .sans(12, .medium),
        .statValue: .serif(22),
        .sectionTitle: .serif(28),
        .body: .sans(16),
        .stepNumber: .serif(19, scales: false),
        .review: .serif(21, .semibold, italic: true),
        .editorTitle: .serif(24),
        .navAction: .sans(17, .medium),
        .navActionProminent: .sans(17, .semibold),
        .fieldHeader: .sans(13, .semibold),
        .fieldTag: .sans(12),
        .titleField: .serif(24),
        .previewMonogram: .serif(28, italic: true, scales: false),
        .button: .sans(16, .semibold),
        .caption: .sans(13),
        .stepBadge: .serif(17, scales: false),
        .stepper: .sans(24, .medium),
        .destructive: .sans(17, .semibold),
    ]

    @Test func everyStyleIsSpecified() {
        #expect(Set(Typography.allCases) == Set(Self.handoff.keys))
    }

    @Test(arguments: Typography.allCases)
    func matchesTheHandoff(_ style: Typography) throws {
        let spec = try #require(Self.handoff[style])
        #expect(style.size == spec.size)
        #expect(style.weight == spec.weight)
        #expect((style.design == .serif) == spec.serif)
        #expect(style.design == .serif || style.design == .default)
        #expect(style.isItalic == spec.italic)
        #expect((style.textStyle != nil) == spec.scales)
    }

    @Test func titlesScaleWithTheLargestTextStyles() {
        #expect(Typography.listTitle.textStyle == .largeTitle)
        #expect(Typography.detailTitle.textStyle == .largeTitle)
        #expect(Typography.sectionTitle.textStyle == .title)
        #expect(Typography.body.textStyle == .callout)
    }

    @Test func onlyTheFieldHeaderIsUppercased() {
        #expect(Typography.allCases.filter(\.isUppercased) == [.fieldHeader])
    }

    @Test func stepTextUsesALineHeightOfOneAndAHalf() {
        #expect(Typography.body.lineSpacing(lineHeight: 1.5) == 8)
    }
}

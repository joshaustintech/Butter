import Foundation
import Testing
@testable import Butter

struct RecipeCatalogTests {
    struct Entry: Catalogued, Equatable {
        let id = UUID()
        let title: String
        let createdAt: Date

        init(_ title: String, day: Double) {
            self.title = title
            createdAt = Date(timeIntervalSince1970: day * 86_400)
        }
    }

    let entries = [
        Entry("Rhubarb Galette", day: 4),
        Entry("apple Crumble", day: 1),
        Entry("Éclairs", day: 6),
        Entry("Lemon Ricotta Pancakes", day: 5),
        Entry("Banana Bread", day: 2),
    ]

    @Test func latestShowsNewestFirst() {
        let titles = RecipeCatalog.arrange(entries, by: .latest, matching: "").map(\.title)
        #expect(titles == ["Éclairs", "Lemon Ricotta Pancakes", "Rhubarb Galette", "Banana Bread", "apple Crumble"])
    }

    @Test func nameSortsAlphabeticallyWithLocalizedComparison() {
        let titles = RecipeCatalog.arrange(entries, by: .name, matching: "").map(\.title)
        let expected = entries.map(\.title).sorted { $0.localizedCompare($1) == .orderedAscending }
        #expect(titles == expected)
    }

    @Test func searchFiltersByTitleIgnoringCaseAndDiacritics() {
        let titles = RecipeCatalog.arrange(entries, by: .latest, matching: "  ECLAIR ").map(\.title)
        #expect(titles == ["Éclairs"])
        let breads = RecipeCatalog.arrange(entries, by: .name, matching: "b").map(\.title)
        #expect(breads == ["Banana Bread", "apple Crumble", "Rhubarb Galette"].sorted { $0.localizedCompare($1) == .orderedAscending })
    }

    @Test func searchWithNoMatchesIsEmpty() {
        #expect(RecipeCatalog.arrange(entries, by: .latest, matching: "zzz").isEmpty)
    }

    @Test func tintsCycleSageButterRoseByCreationOrder() {
        let tints = RecipeCatalog.tints(for: entries)
        let byTitle = Dictionary(uniqueKeysWithValues: entries.map { ($0.title, tints[$0.id]) })
        #expect(byTitle["apple Crumble"] == .sage)
        #expect(byTitle["Banana Bread"] == .butter)
        #expect(byTitle["Rhubarb Galette"] == .rose)
        #expect(byTitle["Lemon Ricotta Pancakes"] == .sage)
        #expect(byTitle["Éclairs"] == .butter)
    }

    @Test func aRecipesTintDoesNotChangeWhenANewerOneIsAdded() {
        let before = RecipeCatalog.tints(for: entries)
        let after = RecipeCatalog.tints(for: entries + [Entry("Scones", day: 9)])
        for entry in entries {
            #expect(before[entry.id] == after[entry.id])
        }
    }

    @Test func subtitleCountsRecipesAndNamesTheSort() {
        #expect(RecipeCatalog.subtitle(count: 6, sort: .latest) == "6 recipes · sorted by latest")
        #expect(RecipeCatalog.subtitle(count: 1, sort: .name) == "1 recipe · sorted by name")
        #expect(RecipeCatalog.subtitle(count: 0, sort: .latest) == "0 recipes · sorted by latest")
    }

    @Test func sortsHaveTheHandoffLabels() {
        #expect(RecipeSort.allCases == [.latest, .name])
        #expect(RecipeSort.allCases.map(\.label) == ["Latest", "Name"])
    }
}

struct LaurelTests {
    let leaves = Laurel.leaves(radius: 80)

    @Test func hasEightLeavesPerSide() {
        #expect(leaves.count == 16)
        #expect(leaves.filter { $0.center.x < 0 }.count == 8)
        #expect(leaves.filter { $0.center.x > 0 }.count == 8)
    }

    @Test func everyLeafSitsOnTheRadius() {
        for leaf in leaves {
            #expect(abs(hypot(leaf.center.x, leaf.center.y) - 80) < 0.001)
        }
    }

    @Test func sidesAreMirrorImages() {
        for pair in stride(from: 0, to: leaves.count, by: 2) {
            let left = leaves[pair], right = leaves[pair + 1]
            #expect(abs(left.center.x + right.center.x) < 0.001)
            #expect(abs(left.center.y - right.center.y) < 0.001)
            #expect(abs(left.rotation.degrees + right.rotation.degrees) < 0.001)
        }
    }

    @Test func matchesTheReferenceArtwork() throws {
        // Reference SVG: translate(161.2 212.5) rotate(205) around a disc centred at (195, 140).
        let first = try #require(leaves.first)
        #expect(abs(first.center.x - (161.2 - 195)) < 0.2)
        #expect(abs(first.center.y - (212.5 - 140)) < 0.2)
        #expect(abs(first.rotation.degrees - 205) < 0.001)
    }
}

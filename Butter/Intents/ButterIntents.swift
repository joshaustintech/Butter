import AppIntents
import SwiftData

private func allRecipes() throws -> [Recipe] {
    let container = try makeContainer()
    return try ModelContext(container).fetch(FetchDescriptor<Recipe>())
}

struct FindRecipesIntent: AppIntent {
    nonisolated static var title: LocalizedStringResource { "Find Recipes" }
    nonisolated static var description: IntentDescription {
        IntentDescription("Finds saved recipes by title or ingredient.")
    }
    nonisolated static var openAppWhenRun: Bool { false }

    @Parameter(title: "Search", requestValueDialog: "What would you like to find?")
    var search: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let answer = RecipeAnswers.answer(to: .find(search), from: try allRecipes())
        return .result(dialog: IntentDialog(stringLiteral: answer))
    }
}

struct RecentRecipesIntent: AppIntent {
    nonisolated static var title: LocalizedStringResource { "Recent Recipes" }
    nonisolated static var description: IntentDescription {
        IntentDescription("Lists recipes you saved today, last week or last month.")
    }
    nonisolated static var openAppWhenRun: Bool { false }

    @Parameter(title: "Time range")
    var range: SavedRange

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let answer = RecipeAnswers.answer(to: .saved(range), from: try allRecipes())
        return .result(dialog: IntentDialog(stringLiteral: answer))
    }
}

struct ButterShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: FindRecipesIntent(),
            phrases: [
                "Find recipes in \(.applicationName)",
                "Search \(.applicationName) for a recipe",
            ],
            shortTitle: "Find Recipes",
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: RecentRecipesIntent(),
            phrases: [
                "What did I save \(\.$range) in \(.applicationName)",
                "Recent recipes in \(.applicationName)",
            ],
            shortTitle: "Recent Recipes",
            systemImageName: "clock"
        )
    }
}

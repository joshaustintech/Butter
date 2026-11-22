import SwiftData
import SwiftUI

@main
struct ButterApp: App {
    var body: some Scene {
        WindowGroup {
            RecipeListView()
                .tint(Palette.accent.color)
        }
        .modelContainer(for: Recipe.self)
    }
}

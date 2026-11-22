import SwiftData
import SwiftUI

@main
struct ButterApp: App {
    private let store = RecipeStore.open()

    var body: some Scene {
        WindowGroup {
            Group {
                switch store {
                case let .success(container):
                    RecipeListView()
                        .modelContainer(container)
                case let .failure(error):
                    StoreUnavailableView(error: error)
                }
            }
            .tint(Palette.accent.color)
        }
    }
}

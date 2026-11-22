import SwiftData
import SwiftUI

@main
struct ButterApp: App {
    private let container: ModelContainer = {
        do { return try makeContainer() } catch { fatalError("Could not create ModelContainer: \(error)") }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .butterTheme()
                .modelContainer(container)
        }
    }
}

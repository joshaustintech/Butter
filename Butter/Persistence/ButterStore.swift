import Foundation
import SwiftData

/// Builds the app's ModelContainer.
///
/// Uses the default local configuration only. CloudKit sync is intentionally
/// not enabled: it needs the iCloud/CloudKit entitlements, which the app owner
/// must add to the target first. The models are already CloudKit-compatible.
enum ButterStore {
    static let schema = Schema([Recipe.self, Ingredient.self, Step.self, Source.self])

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

/// Convenience wrapper so callers can write `makeContainer(inMemory:)`.
func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
    try ButterStore.makeContainer(inMemory: inMemory)
}

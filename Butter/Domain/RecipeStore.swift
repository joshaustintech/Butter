import SwiftData

/// Where recipes are kept on disk.
enum RecipeStore {
    /// Opens the app's store. A failure here (for example a store written by
    /// an incompatible schema) is returned, never swallowed, so the app can
    /// say so instead of running without anywhere to save.
    static func open() -> Result<ModelContainer, Error> {
        Result { try ModelContainer(for: Recipe.self) }
    }
}

extension ModelContext {
    /// Applies `change` and writes it to disk straight away. If the write
    /// fails, the change is undone and the error rethrown, so nothing looks
    /// saved that isn't.
    func commit(_ change: () -> Void) throws {
        change()
        do {
            try save()
        } catch {
            rollback()
            throw error
        }
    }
}

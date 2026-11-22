import SwiftUI

/// Shown instead of the list when the recipe store can't be opened, so the
/// app never appears to work while nothing can be saved.
struct StoreUnavailableView: View {
    let error: Error

    var body: some View {
        ContentUnavailableView {
            Text("Can’t Open Your Recipes")
                .typography(.sectionTitle)
                .foregroundStyle(Palette.ink)
        } description: {
            VStack(spacing: 12) {
                Text("Butter couldn’t open its saved recipes, so nothing can be saved right now.")
                    .typography(.body)
                    .foregroundStyle(Palette.muted)
                Text(SaveFailure.detail(of: error))
                    .typography(.caption)
                    .foregroundStyle(Palette.muted)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.bg)
    }
}

/// A save or delete that didn't reach the disk, ready to show in an alert.
struct SaveFailure: Equatable {
    let title: String
    let message: String

    init(title: String, message: String) {
        self.title = title
        self.message = message
    }

    init(title: String, error: Error) {
        self.title = title
        message = "Your changes are still here. Try again.\n\n\(Self.detail(of: error))"
    }

    /// The most specific reason the error carries, including Core Data's
    /// underlying reason when there is one.
    static func detail(of error: Error) -> String {
        let nsError = error as NSError
        let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError
        let reason = (underlying ?? nsError).userInfo["reason"] as? String
        return [error.localizedDescription, reason].compactMap { $0 }.joined(separator: " ")
    }
}

#Preview("Light") {
    StoreUnavailableView(error: NSError(domain: NSCocoaErrorDomain, code: 134110, userInfo: [NSLocalizedDescriptionKey: "An error occurred during persistent store migration."]))
}

#Preview("Dark") {
    StoreUnavailableView(error: NSError(domain: NSCocoaErrorDomain, code: 134110, userInfo: [NSLocalizedDescriptionKey: "An error occurred during persistent store migration."]))
        .preferredColorScheme(.dark)
}

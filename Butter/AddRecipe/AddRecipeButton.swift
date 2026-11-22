import SwiftUI

/// The "+" toolbar button that starts adding a Recipe.
struct AddRecipeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel("Add recipe")
    }
}

#Preview("Light") {
    AddRecipeButton {}
        .padding(ButterSpacing.md)
        .background(Color.butterBackground)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    AddRecipeButton {}
        .padding(ButterSpacing.md)
        .background(Color.butterBackground)
        .preferredColorScheme(.dark)
}

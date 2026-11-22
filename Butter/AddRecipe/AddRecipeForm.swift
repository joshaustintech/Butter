import SwiftUI
import UIKit

/// The sheet for typing in a Recipe by hand. It owns the text while it is open;
/// the screen that shows it decides what saving and closing do.
struct AddRecipeForm: View {
    @State private var draft: RecipeDraft
    @State private var askingToDiscard: Bool
    let onSave: (RecipeDraft) -> Void
    let onClose: () -> Void

    init(
        draft: RecipeDraft = RecipeDraft(),
        askingToDiscard: Bool = false,
        onSave: @escaping (RecipeDraft) -> Void,
        onClose: @escaping () -> Void
    ) {
        _draft = State(initialValue: draft)
        _askingToDiscard = State(initialValue: askingToDiscard)
        self.onSave = onSave
        self.onClose = onClose
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ButterSpacing.lg) {
                    VStack(alignment: .leading, spacing: ButterSpacing.xs) {
                        Text("Title")
                            .font(.headline)
                            .foregroundStyle(Color.butterLabel)
                        TextField("Recipe title", text: $draft.title)
                            .font(.body)
                            .frame(minHeight: 44)
                            .butterCard()
                    }
                    RecipeTextField(label: "Ingredients", hint: "One per line", text: $draft.ingredientsText)
                    RecipeTextField(label: "Steps", hint: "One per line", text: $draft.stepsText)
                    RecipePhotoField(photo: $draft.photo)
                }
                .padding(ButterSpacing.md)
            }
            .background(Color.butterBackground)
            .navigationTitle("New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: cancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(draft) }
                        .disabled(!draft.canSave)
                }
            }
            .confirmationDialog("Discard this recipe?", isPresented: $askingToDiscard, titleVisibility: .visible) {
                Button("Discard", role: .destructive, action: onClose)
                Button("Keep editing", role: .cancel) {}
            }
        }
        .interactiveDismissDisabled(draft.hasContent)
    }

    private func cancel() {
        if draft.hasContent {
            askingToDiscard = true
        } else {
            onClose()
        }
    }
}

private let previewFilled = RecipeDraft(
    title: "Lemon pancakes",
    ingredientsText: "2 eggs\n1 cup flour\n1 lemon",
    stepsText: "Whisk the eggs.\nFold in the flour.\nCook until golden."
)

private let previewWithPhoto = RecipeDraft(
    title: previewFilled.title,
    ingredientsText: previewFilled.ingredientsText,
    stepsText: previewFilled.stepsText,
    photo: UIImage(systemName: "fork.knife")?.pngData()
)

#Preview("Light, empty") {
    AddRecipeForm(onSave: { _ in }, onClose: {})
        .preferredColorScheme(.light)
}

#Preview("Dark, empty") {
    AddRecipeForm(onSave: { _ in }, onClose: {})
        .preferredColorScheme(.dark)
}

#Preview("Light, filled") {
    AddRecipeForm(draft: previewFilled, onSave: { _ in }, onClose: {})
        .preferredColorScheme(.light)
}

#Preview("Dark, filled") {
    AddRecipeForm(draft: previewFilled, onSave: { _ in }, onClose: {})
        .preferredColorScheme(.dark)
}

#Preview("Light, with photo") {
    AddRecipeForm(draft: previewWithPhoto, onSave: { _ in }, onClose: {})
        .preferredColorScheme(.light)
}

#Preview("Dark, with photo") {
    AddRecipeForm(draft: previewWithPhoto, onSave: { _ in }, onClose: {})
        .preferredColorScheme(.dark)
}

#Preview("Light, discard question") {
    AddRecipeForm(draft: previewFilled, askingToDiscard: true, onSave: { _ in }, onClose: {})
        .preferredColorScheme(.light)
}

#Preview("Dark, discard question") {
    AddRecipeForm(draft: previewFilled, askingToDiscard: true, onSave: { _ in }, onClose: {})
        .preferredColorScheme(.dark)
}

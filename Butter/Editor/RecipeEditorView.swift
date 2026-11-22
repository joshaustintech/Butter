import SwiftData
import SwiftUI

/// The Create / Edit Recipe sheet. Works on a draft; nothing is written
/// until Save, and Cancel throws the draft away.
struct RecipeEditorView: View {
    enum Mode {
        case new
        case edit(Recipe)

        var title: String {
            switch self {
            case .new: "New Recipe"
            case .edit: "Edit Recipe"
            }
        }
    }

    let mode: Mode
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var draft: RecipeDraft
    @State private var original: RecipeDraft
    @State private var isConfirmingDelete = false
    @State private var failure: SaveFailure?

    init(mode: Mode) {
        self.mode = mode
        let draft = switch mode {
        case .new: RecipeDraft()
        case let .edit(recipe): RecipeDraft(recipe.content)
        }
        _draft = State(initialValue: draft)
        _original = State(initialValue: draft)
    }

    var body: some View {
        VStack(spacing: 0) {
            EditorBar(
                title: mode.title,
                canSave: draft.content != nil,
                onCancel: { dismiss() },
                onSave: save
            )
            ScrollView {
                VStack(spacing: 22) {
                    TitleSection(title: $draft.title)
                    PhotoSection(photo: $draft.photo, title: draft.title)
                    DetailsSection(draft: $draft)
                    RatingSection(rating: $draft.rating)
                    IngredientsSection(draft: $draft)
                    MethodSection(draft: $draft)
                    ReviewNotesSection(notes: $draft.reviewNotes)
                    if case .edit = mode {
                        DeleteRecipeButton { isConfirmingDelete = true }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Palette.bg)
        .presentationBackground(Palette.bg)
        .interactiveDismissDisabled(draft != original)
        .confirmationDialog("Delete this recipe?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete Recipe", role: .destructive, action: delete)
        } message: {
            Text("This can’t be undone.")
        }
        .alert(
            failure?.title ?? "",
            isPresented: Binding(get: { failure != nil }, set: { if !$0 { failure = nil } }),
            presenting: failure
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { failure in
            Text(failure.message)
        }
    }

    private func save() {
        guard let content = draft.content else {
            failure = SaveFailure(title: "Couldn’t Save Recipe", message: "Give the recipe a title first.")
            return
        }
        do {
            try modelContext.commit {
                switch mode {
                case .new: modelContext.insert(Recipe(content: content))
                case let .edit(recipe): recipe.content = content
                }
            }
            dismiss()
        } catch {
            failure = SaveFailure(title: "Couldn’t Save Recipe", error: error)
        }
    }

    private func delete() {
        guard case let .edit(recipe) = mode else { return }
        do {
            try modelContext.commit { modelContext.delete(recipe) }
            dismiss()
        } catch {
            failure = SaveFailure(title: "Couldn’t Delete Recipe", error: error)
        }
    }
}

#if DEBUG
#Preview("Edit, Light") {
    RecipeEditorView(mode: .edit(PreviewSamples.recipe()))
        .modelContainer(PreviewSamples.container)
}

#Preview("Edit, Dark") {
    RecipeEditorView(mode: .edit(PreviewSamples.recipe()))
        .modelContainer(PreviewSamples.container)
        .preferredColorScheme(.dark)
}

#Preview("New, Light") {
    RecipeEditorView(mode: .new)
        .modelContainer(PreviewSamples.emptyContainer)
}

#Preview("New, Dark") {
    RecipeEditorView(mode: .new)
        .modelContainer(PreviewSamples.emptyContainer)
        .preferredColorScheme(.dark)
}
#endif

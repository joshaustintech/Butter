import SwiftUI

/// An editor section: an uppercase header marked Required or Optional,
/// an optional Reorder / Done button, then the section's fields.
struct EditorSection<Content: View>: View {
    enum Requirement {
        case required, optional

        var label: String { self == .required ? "Required" : "Optional" }
    }

    /// The header's Reorder / Done toggle.
    struct Reorder {
        @Binding var isOn: Bool
        var isEnabled = true
    }

    let title: String
    var requirement = Requirement.optional
    var reorder: Reorder?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
                .padding(.horizontal, 4)
            content
        }
    }

    @ViewBuilder
    private var header: some View {
        let heading = Text(title)
            .typography(.fieldHeader)
            .accessibilityAddTraits(.isHeader)
        let tag = Text(requirement.label)
            .typography(.fieldTag)
        if let reorder {
            HStack(alignment: .center) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    heading
                    tag
                }
                .foregroundStyle(Palette.muted)
                Spacer()
                ReorderButton(isReordering: reorder.$isOn)
                    .disabled(!reorder.isEnabled)
            }
            .frame(minHeight: 32)
        } else {
            HStack(alignment: .firstTextBaseline) {
                heading
                Spacer()
                tag
            }
            .foregroundStyle(Palette.muted)
        }
    }
}

#Preview("Light") {
    @Previewable @State var isReordering = false
    VStack(spacing: 22) {
        EditorSection(title: "Title", requirement: .required) {
            Text("Fields").frame(maxWidth: .infinity, minHeight: 52).card(cornerRadius: 14)
        }
        EditorSection(title: "Details", reorder: .init(isOn: $isReordering)) {
            Text("Fields").frame(maxWidth: .infinity, minHeight: 52).card(cornerRadius: 14)
        }
    }
    .padding(16)
    .background(Palette.bg)
}

#Preview("Dark") {
    @Previewable @State var isReordering = true
    VStack(spacing: 22) {
        EditorSection(title: "Title", requirement: .required) {
            Text("Fields").frame(maxWidth: .infinity, minHeight: 52).card(cornerRadius: 14)
        }
        EditorSection(title: "Details", reorder: .init(isOn: $isReordering)) {
            Text("Fields").frame(maxWidth: .infinity, minHeight: 52).card(cornerRadius: 14)
        }
    }
    .padding(16)
    .background(Palette.bg)
    .preferredColorScheme(.dark)
}

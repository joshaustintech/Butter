import SwiftUI

/// A small right-aligned numeric field. Whatever is typed is reduced to a
/// positive whole number of up to four digits; blank means not set.
struct WholeNumberField: View {
    @Binding var value: WholeNumber?
    let label: String
    let unit: String?
    @State private var text: String

    init(value: Binding<WholeNumber?>, label: String, unit: String?) {
        _value = value
        self.label = label
        self.unit = unit
        _text = State(initialValue: value.wrappedValue?.description ?? "")
    }

    var body: some View {
        HStack(spacing: 4) {
            TextField(label, text: $text, prompt: Text("Optional").foregroundStyle(Palette.muted))
                .typography(.body)
                .foregroundStyle(Palette.ink)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .padding(.horizontal, 12)
                .frame(width: 96, height: 44)
                .background(Palette.bg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Palette.line, lineWidth: 1)
                }
                .accessibilityLabel(unit == nil ? label : "\(label) in minutes")
            Text(unit ?? "")
                .typography(.body)
                .foregroundStyle(Palette.muted)
                .frame(minWidth: 34, alignment: .leading)
                .accessibilityHidden(true)
        }
        .onChange(of: text) { _, typed in
            let clean = WholeNumber.sanitized(typed)
            if clean != typed { text = clean }
            value = WholeNumber(digits: clean)
        }
    }
}

#Preview("Light") {
    @Previewable @State var minutes = WholeNumber(30)
    WholeNumberField(value: $minutes, label: "Prep time", unit: "min")
        .padding()
        .background(Palette.card)
}

#Preview("Dark") {
    @Previewable @State var servings: WholeNumber?
    WholeNumberField(value: $servings, label: "Serves", unit: nil)
        .padding()
        .background(Palette.card)
        .preferredColorScheme(.dark)
}

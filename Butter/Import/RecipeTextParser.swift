import Foundation

/// Turns plain text recognized from a photographed recipe page into a best-effort
/// `ImportedRecipe`. Pure and total: it never fails, and empty input yields an
/// untitled, empty recipe.
nonisolated enum RecipeTextParser {
    static func parse(text: String) -> ImportedRecipe {
        let lines = text
            .split(whereSeparator: { $0.isNewline })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var title = "Untitled Recipe"
        var body = lines[...]
        if let first = lines.first, headingSection(for: first) == nil {
            title = first
            body = body.dropFirst()
        }

        var draft = Draft()
        var current: Section?
        for raw in body {
            let line = stripBullet(raw)
            guard !line.isEmpty else { continue }
            if let heading = headingSection(for: line) {
                current = heading
                continue
            }
            switch current {
            case .ingredients: draft.ingredients.append(line)
            case .steps: draft.addStep(line)
            case nil: draft.addUnlabeled(line)
            }
        }

        return ImportedRecipe(
            title: title,
            ingredients: draft.ingredients,
            steps: draft.steps,
            sourceURL: nil,
            imageURL: nil
        )
    }

    private nonisolated enum Section {
        case ingredients, steps
    }

    private nonisolated struct Draft {
        var ingredients: [String] = []
        var steps: [String] = []
        /// Set once a "1." or "Step 2:" marker is seen. After that, a line that does not
        /// start with a number or capital letter is a wrapped line, not a new step.
        private var sawNumbering = false

        /// Lines under a Steps heading, or unlabeled lines that look like steps.
        mutating func addStep(_ line: String) {
            if let text = RecipeTextParser.textAfterStepMarker(line) {
                sawNumbering = true
                if !text.isEmpty { steps.append(text) }
                return
            }
            guard let first = line.first else { return }
            let isWrapped = first.isLowercase || (sawNumbering && !first.isUppercase && !first.isNumber)
            if isWrapped, !steps.isEmpty {
                steps[steps.count - 1] += " " + line
            } else {
                steps.append(line)
            }
        }

        /// Lines before any heading, or in a recipe with no headings at all.
        mutating func addUnlabeled(_ line: String) {
            if RecipeTextParser.textAfterStepMarker(line) != nil {
                addStep(line)
            } else if RecipeTextParser.startsWithQuantity(line) {
                ingredients.append(line)
            } else if (line.first?.isLowercase == true && !steps.isEmpty)
                        || RecipeTextParser.looksLikeSentence(line) {
                addStep(line)
            }
            // Anything else (a short label such as "Serves 4") is dropped.
        }
    }

    private nonisolated static let unitWords: Set<String> = [
        "cup", "cups", "tbsp", "tbs", "tablespoon", "tablespoons",
        "tsp", "teaspoon", "teaspoons", "oz", "ounce", "ounces",
        "lb", "lbs", "pound", "pounds", "g", "gram", "grams", "kg",
        "ml", "l", "liter", "liters", "litre", "litres",
        "pinch", "pinches", "dash", "dashes", "clove", "cloves",
        "pint", "pints", "quart", "quarts",
    ]

    private nonisolated static let bulletCharacters: Set<Character> = [
        "-", "•", "*", "–", "—", "·", "◦", "▪", "●",
    ]

    private static func headingSection(for line: String) -> Section? {
        var key = line.lowercased().trimmingCharacters(in: .whitespaces)
        if key.hasSuffix(":") { key.removeLast() }
        switch key.trimmingCharacters(in: .whitespaces) {
        case "ingredients": return .ingredients
        case "directions", "method", "instructions", "steps": return .steps
        default: return nil
        }
    }

    private static func stripBullet(_ line: String) -> String {
        guard let first = line.first, bulletCharacters.contains(first) else { return line }
        return String(line.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The text after a "1.", "2)" or "Step 3:" marker, or nil when the line has none.
    /// The marker must be followed by whitespace, so "1.5 cups" is not a marker.
    private static func textAfterStepMarker(_ line: String) -> String? {
        let marker = /^(?:step\s+\d+\s*[:.)\-–]?\s*|\d+\s*[.)]\s+)/.ignoresCase()
        guard let match = line.prefixMatch(of: marker) else { return nil }
        return String(line[match.range.upperBound...])
    }

    /// A line starting with a number, a fraction such as ½, or a measurement word.
    private static func startsWithQuantity(_ line: String) -> Bool {
        guard let first = line.first else { return false }
        if first.isNumber { return true }
        return unitWords.contains(line.prefix(while: { $0.isLetter }).lowercased())
    }

    /// Long lines, or lines ending a sentence, are treated as steps.
    private static func looksLikeSentence(_ line: String) -> Bool {
        line.count >= 30 || line.hasSuffix(".") || line.hasSuffix("!") || line.hasSuffix("?")
    }
}

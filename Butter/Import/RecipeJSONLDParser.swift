import Foundation

/// Reads a schema.org Recipe out of the JSON-LD blocks of a webpage.
nonisolated enum RecipeJSONLDParser {
    static func parse(html: String, pageURL: URL?) -> ImportedRecipe? {
        for block in jsonLDBlocks(in: html) {
            guard let data = block.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            else { continue }
            if let recipe = findRecipe(in: json, depth: 0, pageURL: pageURL) {
                return recipe
            }
        }
        return nil
    }

    // MARK: - Locating

    private static func jsonLDBlocks(in html: String) -> [String] {
        let pattern = #"<script\b[^>]*\btype\s*=\s*["']?application/ld\+json["']?[^>]*>(.*?)</script\s*>"#
        guard let regex = try? NSRegularExpression(
            pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else { return [] }
        let ns = html as NSString
        return regex.matches(in: html, range: NSRange(location: 0, length: ns.length)).map {
            ns.substring(with: $0.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private static func findRecipe(in value: Any, depth: Int, pageURL: URL?) -> ImportedRecipe? {
        guard depth < 8 else { return nil }
        if let array = value as? [Any] {
            for item in array {
                if let recipe = findRecipe(in: item, depth: depth + 1, pageURL: pageURL) { return recipe }
            }
            return nil
        }
        guard let object = value as? [String: Any] else { return nil }
        if isRecipe(object), let recipe = build(from: object, pageURL: pageURL) {
            return recipe
        }
        for key in ["@graph", "mainEntity", "mainEntityOfPage"] {
            if let nested = object[key],
               let recipe = findRecipe(in: nested, depth: depth + 1, pageURL: pageURL) {
                return recipe
            }
        }
        return nil
    }

    private static func isRecipe(_ object: [String: Any]) -> Bool {
        let types: [String]
        if let string = object["@type"] as? String {
            types = [string]
        } else if let array = object["@type"] as? [Any] {
            types = array.compactMap { $0 as? String }
        } else {
            return false
        }
        return types.contains { type in
            let last = type.split(whereSeparator: { $0 == "/" || $0 == ":" || $0 == "#" }).last.map(String.init) ?? type
            return last.lowercased() == "recipe"
        }
    }

    // MARK: - Building

    private static func build(from object: [String: Any], pageURL: URL?) -> ImportedRecipe? {
        guard let rawName = object["name"] as? String ?? object["headline"] as? String else { return nil }
        let title = cleanText(rawName)
        guard !title.isEmpty else { return nil }

        let ingredients = lines(from: object["recipeIngredient"] ?? object["ingredients"])
        let steps = instructionSteps(from: object["recipeInstructions"])
        let imageURL = imageString(from: object["image"]).flatMap { resolve($0, against: pageURL) }

        return ImportedRecipe(
            title: title,
            ingredients: ingredients,
            steps: steps,
            sourceURL: pageURL,
            imageURL: imageURL
        )
    }

    private static func lines(from value: Any?) -> [String] {
        if let string = value as? String { return splitLines(string) }
        if let array = value as? [Any] { return array.flatMap { lines(from: $0) } }
        return []
    }

    private static func instructionSteps(from value: Any?) -> [String] {
        if let string = value as? String { return splitLines(string) }
        if let array = value as? [Any] { return array.flatMap { instructionSteps(from: $0) } }
        guard let object = value as? [String: Any] else { return [] }
        if let nested = object["itemListElement"] {
            return instructionSteps(from: nested)
        }
        for key in ["text", "description", "name"] {
            if let string = object[key] as? String {
                let result = splitLines(string)
                if !result.isEmpty { return result }
            }
        }
        return []
    }

    private static func imageString(from value: Any?) -> String? {
        if let string = value as? String { return string.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let array = value as? [Any] {
            for item in array {
                if let found = imageString(from: item), !found.isEmpty { return found }
            }
            return nil
        }
        if let object = value as? [String: Any] {
            return imageString(from: object["url"] ?? object["contentUrl"])
        }
        return nil
    }

    private static func resolve(_ string: String, against base: URL?) -> URL? {
        guard !string.isEmpty else { return nil }
        if let base, let url = URL(string: string, relativeTo: base)?.absoluteURL { return url }
        return URL(string: string)
    }

    // MARK: - Text cleanup

    /// Splits on line breaks (including block-level tags), then cleans each line.
    private static func splitLines(_ raw: String) -> [String] {
        var text = raw
        text = text.replacingOccurrences(
            of: #"(?i)<br\s*/?>|</(p|li|div|ol|ul|h[1-6])\s*>"#, with: "\n", options: .regularExpression
        )
        return text.components(separatedBy: .newlines)
            .map(cleanText)
            .filter { !$0.isEmpty }
    }

    private static func cleanText(_ raw: String) -> String {
        var text = raw.replacingOccurrences(of: #"<[^>]*>"#, with: " ", options: .regularExpression)
        text = decodeEntities(text)
        text = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let namedEntities: [String: String] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": " ",
        "ndash": "\u{2013}", "mdash": "\u{2014}", "rsquo": "\u{2019}", "lsquo": "\u{2018}",
        "rdquo": "\u{201D}", "ldquo": "\u{201C}", "deg": "\u{00B0}", "frac12": "\u{00BD}",
        "frac14": "\u{00BC}", "frac34": "\u{00BE}", "hellip": "\u{2026}", "eacute": "\u{00E9}",
    ]

    private static func decodeEntities(_ text: String) -> String {
        guard text.contains("&"),
              let regex = try? NSRegularExpression(pattern: #"&(#[xX][0-9a-fA-F]+|#[0-9]+|[a-zA-Z][a-zA-Z0-9]*);"#)
        else { return text }
        let ns = text as NSString
        var result = ""
        var last = 0
        for match in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            result += ns.substring(with: NSRange(location: last, length: match.range.location - last))
            let body = ns.substring(with: match.range(at: 1))
            var replacement: String?
            if body.hasPrefix("#") {
                let digits = body.dropFirst()
                let scalarValue: UInt32? = digits.first == "x" || digits.first == "X"
                    ? UInt32(digits.dropFirst(), radix: 16) : UInt32(digits)
                replacement = scalarValue.flatMap(Unicode.Scalar.init).map { String(Character($0)) }
            } else {
                replacement = namedEntities[body] ?? namedEntities[body.lowercased()]
            }
            result += replacement ?? ns.substring(with: match.range)
            last = match.range.location + match.range.length
        }
        result += ns.substring(from: last)
        return result
    }
}

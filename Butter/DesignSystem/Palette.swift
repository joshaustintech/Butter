import SwiftUI

/// The "Cottage Core" colour tokens. Each is an adaptive colour in the asset
/// catalog (Any = light, Dark = dark), so the app follows the system appearance.
enum Palette: String, CaseIterable, ShapeStyle {
    case bg, card, fill, line, ink, muted, accent, onAccent, star, leaf
    case danger, dangerLine, tintSage, tintButter, tintRose, hero0, hero1, chevron

    var color: Color { Color(rawValue, bundle: .main) }

    func resolve(in environment: EnvironmentValues) -> Color.Resolved {
        color.resolve(in: environment)
    }
}

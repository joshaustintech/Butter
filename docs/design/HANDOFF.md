# Cottage Butter handoff

## What is in place

- **Tokens:** `docs/design/tokens.json` is the source of truth for color, spacing, radius, type and touch targets.
- **Colors:** 12 tokens in `Butter/DesignSystem/Colors.xcassets`, each with a light and dark variant. Dark mode is automatic.
- **SwiftUI:** `ButterTheme.swift` (colors, spacing, radius, `Font.butterDisplay`, `butterTheme()`), `ButterComponents.swift` (`.butterPrimary`, `.butterSecondary`, `.butterCard()`, `ButterChip`), and `DesignGallery.swift` (light and dark previews).
- **App assets:** sage `AccentColor`, app icon with light, dark and tinted variants (generated placeholder mark: cream plate, sage leaf), launch screen background set to `ButterBackground`.
- **Root:** `ButterApp` applies `.butterTheme()`, and `ContentView` uses `butterBackground`.
- **Tests:** `ButterTests/DesignTokenTests.swift` checks that every color token resolves in light and dark.
- **Checks:** `scripts/check_design_tokens.py` checks token/colorset/Swift consistency and blocks hard-coded colors and fonts in feature code.
- **Agent harness:** `AGENTS.md` design section and the `butter-design` skill in `.claude/skills/`.

## Not yet verified

- The Swift code has not been compiled or run. The environment used to write it has no Xcode or Swift toolchain. Build the `Butter` scheme and run `ButterTests`, then check the previews in light and dark.
- The app icon is a placeholder mark, not a final brand icon.
- The Cottage Butter canvas uses web stand-ins for layout. The Swift components are the source of truth where they differ.

## Next steps

1. Build and test in Xcode. Fix any compile issues in `Butter/DesignSystem/`.
2. Review the gallery previews on device or simulator, in light and dark, at the largest Dynamic Type size.
3. Replace the placeholder app icon with the final mark when it is ready.
4. Build the first recipe screens on top of the components.

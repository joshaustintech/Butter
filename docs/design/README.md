# Cottage Butter design system

Butter's look: a sunlit butter-yellow ground, soft sage and blush accents, warm ink text, and generous rounded corners. Built only from what iOS and SwiftUI already provide, so it adapts to Dynamic Type, Dark Mode, and accessibility settings without extra work.

- **Tokens (source of truth):** `tokens.json` in this folder
- **SwiftUI implementation:** `Butter/DesignSystem/`
  - `Colors.xcassets` holds every color with a light and a dark variant.
  - `ButterTheme.swift` holds colors, spacing, radii, and the display font.
  - `ButterComponents.swift` holds button styles, the card modifier, and chips.
  - `DesignGallery.swift` is a preview-only visual check.
- **App-level assets:** `Butter/Assets.xcassets` holds the sage `AccentColor` (system tint) and the app icon (light, dark and tinted).
- **Checks:** `ButterTests/DesignTokenTests.swift` (every color token exists in light and dark) and `scripts/check_design_tokens.py` (tokens match colorsets, no hard-coded colors or fonts in feature code).
- **Agent guidance:** `AGENTS.md` and `.claude/skills/butter-design/SKILL.md`.

## Platform choices

- **Text** uses SF Pro through Dynamic Type text styles (`.body`, `.headline`, `.title2`). It is never set to a fixed size.
- **Display** uses New York, the system serif (`Font.butterDisplay(_:)`). It is used sparingly for warmth, not for reading.
- **Icons** are SF Symbols (`Image(systemName:)`), so they match weight and scale with text.
- **Shapes** use continuous corners (`style: .continuous`) and `Capsule` for pills, matching native iOS.
- **Tint** is sage (`butterAccent`), set once with `.butterTheme()`. Butter yellow is a fill, not a tint, because yellow links fail contrast on cream.

## Usage rules

1. Use `Color.butter*` tokens. Do not write hex values or `Color(red:green:blue:)` in feature code.
2. Yellow (`butterPrimary`) is for fills. Text and icons on yellow use `butterOnPrimary`.
3. Body copy uses `butterLabel`. Supporting copy uses `butterLabelSecondary`.
4. Tap targets are at least 44 pt. Primary buttons are 50 pt tall.
5. Text contrast is at least 4.5:1. Check any new pairing against the dark variant too.
6. Use `.butterPrimary` for the one main action on a screen and `.butterSecondary` for alternatives.
7. Group content on `butterSurface` with `.butterCard()`, not with borders or shadows.
8. Use `Font.butterDisplay` for at most two elements per screen.

## Changing a token

Update `tokens.json`, the matching `Colors.xcassets` colorset (both light and dark), and `ButterTheme.swift` in the same change. Then check the Xcode previews in light and dark.

## Enforcement

Run `python3 scripts/check_design_tokens.py` before finishing any UI change. It fails on hard-coded colors, hex literals, fixed font sizes and custom fonts outside `Butter/DesignSystem/`, and on tokens that drift from their colorsets.

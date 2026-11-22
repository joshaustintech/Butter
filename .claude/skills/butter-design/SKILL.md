---
name: butter-design
description: Use when building, changing or reviewing any SwiftUI view, screen, component or style in the Butter app, so it uses the Cottage Butter design system tokens and components instead of hard-coded values.
---

# Butter design system

Every piece of UI in Butter is built from the Cottage Butter design system. Read `docs/design/README.md` for the full rules, and `docs/design/tokens.json` for the token values.

## Workflow

1. Before writing UI, look at the components that already exist in `Butter/DesignSystem/`: `ButterTheme.swift` (colors, spacing, radius, display font), `ButterComponents.swift` (`.butterPrimary`, `.butterSecondary`, `.butterCard()`, `ButterChip`) and `DesignGallery.swift` (the visual reference).
2. Build the view from those tokens. Use:
   - `Color.butter*` for color. Never hex values or `Color(red:green:blue:)`.
   - `ButterSpacing.*` and `ButterRadius.*` for padding, gaps and corners. Use `style: .continuous`.
   - Dynamic Type text styles (`.body`, `.headline`, `.title2`) for text. `Font.butterDisplay(_:)` for at most two display titles per screen.
   - `Image(systemName:)` with SF Symbols for icons.
   - `.butterPrimary` for the main action and `.butterSecondary` for alternatives. Tap targets are at least 44 pt.
3. If a new token or component is really needed, add it to the design system first: `tokens.json`, the colorset in both light and dark, `ButterTheme.swift`, and a preview in `DesignGallery.swift`. Then use it from the feature.
4. Add a `#Preview` in both light and dark for any new screen or component.
5. Run `python3 scripts/check_design_tokens.py` from the repo root. It must pass before the work is finished.

## Never

- Hard-code colors, hex values, fixed font sizes or custom fonts in feature code.
- Use butter yellow (`butterPrimary`) for text or error messages. Use `butterOnPrimary` for text on yellow.
- Add borders or shadows to group content. Use `.butterCard()`.

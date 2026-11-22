# AGENTS.md

## Agent skills

### Issue tracker

Issues are tracked in GitHub Issues on joshaustintech/Butter (via `gh`). See `docs/agents/issue-tracker.md`.

### Triage labels

Default canonical labels: needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: root `GLOSSARY.md` + `docs/adr/` (created lazily). See `docs/agents/domain.md`.

## Design system

Every screen and component follows the Cottage Butter design system. Before building or changing any UI:

- Read `docs/design/README.md` (rules) and use the `butter-design` skill in `.claude/skills/butter-design/`.
- Tokens: `docs/design/tokens.json`. SwiftUI implementation: `Butter/DesignSystem/` (`ButterTheme.swift`, `ButterComponents.swift`, `DesignGallery.swift`). Colors: `Butter/DesignSystem/Colors.xcassets`. Accent and app icon: `Butter/Assets.xcassets`.
- Use `Color.butter*`, `ButterSpacing`, `ButterRadius`, Dynamic Type text styles, `Font.butterDisplay(_:)`, SF Symbols, `.butterPrimary`, `.butterSecondary`, `.butterCard()` and `ButterChip`. No hard-coded colors, fixed font sizes or custom fonts outside `Butter/DesignSystem/`.
- Yellow is a fill, never text or error color. Tap targets are at least 44 pt.
- Before finishing UI work, run `python3 scripts/check_design_tokens.py` from the repo root. It must pass.
- When a token changes, update `tokens.json`, its colorset (light and dark), `ButterTheme.swift`, and the gallery preview together.

## Code architecture

Keep SwiftUI plain, so a person can read each file top to bottom.

- Build with simple Views in parent-child relationships. The root View owns the app state and passes it down through parameters and bindings. Skip MVVM and other layered patterns.
- Give every design-system component and every reusable UI element its own View in its own file.
- Give every View, screen and component a working `#Preview`, in light and dark, so a human can review the design. A View without one is unfinished.

# Butter — SwiftUI Handoff

Build an iPhone app (SwiftUI only, iOS 17+, portrait) that matches the design exactly. **Build everything listed here and nothing else.** No extra screens, tabs, settings, sharing, import/export, tags, categories, onboarding, or animations beyond system defaults.

Reference: `reference/` holds the design source (`*.dc.html`, open in a browser; light and dark versions of each screen, a sparse-recipe detail, and an empty New Recipe editor). Where this file and the reference differ, this file wins. The reference is an HTML mockup; use it for layout, spacing, and colors, not as code to port.

## Look: "Cottage Core"

- **Fonts (SwiftUI only):** titles and headings in the system serif (`.system(.…, design: .serif)`, i.e. New York), bold. Body text, buttons, labels, fields in the default SF Pro. Use Dynamic Type text styles scaled to the sizes below.
- Monograms and the review quote use serif **italic**.
- Icons: SF Symbols only (`plus`, `magnifyingglass`, `chevron.right`, `chevron.left`, `star`, `star.fill`, `star.leadinghalf.filled`, `line.3.horizontal`, `minus.circle`, `plus.circle`, `camera`).
- Corner radii: cards 14–16, tiles 14, small fields 10–12, circular buttons fully round.

### Colors (define adaptive colors in the asset catalog: Any = light, Dark = dark)

| Token | Light | Dark | Use |
|---|---|---|---|
| bg | #F5EEDF | #1F1A15 | screen background |
| card | #FBF7EC | #2A231C | grouped cards, fields |
| fill | #E9DFCB | #352C23 | search field, segmented track, photo row |
| line | #E2D6BD | #433829 | borders, dividers |
| ink | #3B2E25 | #F1E8D6 | primary text |
| muted | #6B5A4C | #BBAC95 | secondary text |
| accent | #4F6340 | #A9C08F | buttons, links, step badges (app tint) |
| onAccent | #FBF7EC | #1F1A15 | text/icons on accent fills |
| star | #B8862B | #E0B352 | rating stars |
| leaf | #8FA37A | #6F8A5A | bullets, laurel, dashed photo border |
| danger | #9A4A46 | #E59A94 | remove, Delete Recipe text |
| dangerLine | #D2B0AB | #6B403C | Delete Recipe border |
| tintSage | #D5DFC4 | #3B4630 | tiles |
| tintButter | #F0DDA0 | #4D4222 | tiles |
| tintRose | #EBC9C4 | #4F3030 | tiles |
| hero0 | #EBC9C4 | #33241F | detail hero background |
| hero1 | #F4DDD8 | #3E2B27 | monogram disc |
| chevron | #8A7868 | #8F806C | list disclosure chevron |

Follows system light/dark automatically. Minimum touch target 44×44 pt.

## Data model

`Recipe`: `id`, `title` (required, String), `createdAt` (Date), `photo` (optional image data), `prepMinutes` (Int?), `bakeMinutes` (Int?), `servings` (Int?), `detailOrder` ([prep, bake, serves], default that order), `rating` (Double?, 0.5–5.0 in 0.5 steps, nil = unrated), `ingredients` ([String], ordered), `steps` ([String], ordered), `reviewNotes` (String, optional).

**Everything except the title is optional.** Time/servings are positive whole numbers or nil. Persist locally with SwiftData (this is storage for the catalog, not a feature in the design).

## Screens

Root: `NavigationStack` on the Recipes List. Detail is pushed. Create/Edit is presented as a sheet.

### 1. Recipes List
- Large serif title **"Recipes"** (44 bold), subtitle line (14, muted): `"{N} recipes · sorted by latest"` or `"… sorted by name"`.
- Top-right circular **+** button (44 pt, accent fill, onAccent icon) opens the editor in New mode.
- Search field (44 pt tall, fill background, radius 12, magnifying glass, placeholder "Search recipes"). Filters the list by title.
- Segmented control: **Latest | Name**. Default **Latest** (newest `createdAt` first). **Name** sorts A→Z (`localizedCompare`). Selected segment uses card background with a subtle shadow in light mode.
- Rows in one rounded card (card bg, 1 pt line border, radius 16, 1 pt line dividers). Each row, min 60 pt tall, 12×14 padding:
  - 60×60 tile, radius 14, tint cycling sage → butter → rose by stable order, containing the recipe's **first letter** (serif italic bold 30, ink). If the recipe has a photo, show the photo cropped in the tile instead.
  - Title in serif bold 21.
  - Meta line (13, muted): `★ 4.5` only if rated (single filled star in `star` color + one-decimal number); total time (`prep + bake`, whichever are set) formatted `10 min`, `1 hr 20 min`, `3 hr`, only if any time is set. If neither rating nor time exists, show **"No details yet"**.
  - Trailing chevron.
- Tapping a row pushes Recipe Detail.

### 2. Recipe Detail
- No sorting or reordering of any kind on this screen.
- Overlaid at top: **back pill** ("‹ Recipes", card bg, accent text) and **Edit** pill (accent fill, onAccent text, 44 pt tall). Edit opens the editor in Edit mode for this recipe.
- **Hero**, 240 pt tall, full width. If the recipe has a photo, the photo fills it. **If not, show a monogram:** hero0 background, a centered 124 pt disc (hero1 fill, 2 pt accent ring, plus a 1 pt accent inner ring inset 6 pt) containing the title's **first letter only**, serif italic bold 72, ink; behind the disc, a laurel of 16 small leaf ellipses (11×4.5 pt, `leaf` color) — 8 per side arcing around the disc at radius 80, mirrored left/right.
- Title: serif bold 38.
- Rating row (14, muted): five stars supporting half stars (16 pt, `star` color) + `4.5` (one decimal) + ` · Added Nov 18` (`MMM d`). If unrated, hide stars and the number and the `·`, showing only `Added Nov 18`.
- **Stats tiles** (Prep / Bake / Serves): a row of equal-width tiles, radius 14, padding 12. Label 12 medium muted; value serif bold 22 (`30 min`, `1 hr 20 min`, `6`). Tints: Prep sage, Bake butter, Serves rose. **Only tiles with a value are shown**; hide the whole row if none. Tile order follows the recipe's saved `detailOrder`.
- **Ingredients** (section title serif bold 28): card with 7 pt `leaf` bullet dots, 16 pt text, rows min 44 pt, line dividers. Hidden if there are no ingredients.
- **Method** (serif bold 28): numbered list; 32 pt accent circle with onAccent serif bold 19 number, step text 16 pt, line height 1.5. Hidden if no steps.
- **My Review** (serif bold 28): card containing the notes in serif italic semibold 21. Hidden if no notes.
- Whole screen scrolls.

### 3. Create / Edit Recipe (sheet)
- Nav bar: **Cancel** (left, accent), serif bold 24 title **"New Recipe"** or **"Edit Recipe"**, **Save** (right, accent semibold). Save is disabled when the title is empty. Cancel discards changes. Screen is a scrolling form of sections; each section has an uppercase 13 semibold muted header, with a small muted **"Optional"** (12) on the right for every section except Title, which says **"Required"**.
- **Title**: single-line field (52 pt, card bg, serif bold 24, radius 14), placeholder "Recipe name".
- **Photo (optional)**: a dashed-border row (1.5 pt `leaf` dashes, fill bg, radius 16). Left: 72 pt preview — the chosen photo, or a monogram preview (first letter of the current title, same style as the detail hero but small: 52 pt disc, serif italic bold 28). Right: "Add Photo" (16 semibold accent) and caption "Without one, the title's first letter is shown." (13 muted). Uses `PhotosPicker`.
- **Details (optional)**: card with three rows — **Prep time**, **Bake time**, **Serves** — each a label (16) and a right-aligned numeric field (96×44, radius 10, bg background, placeholder "Optional"; prep and bake show a "min" suffix). Digits only, positive whole numbers, no leading zeros, max 4 digits; blank = not set. Footnote (13 muted): "Type a whole number, or leave blank to skip it." Section header has a **Reorder / Done** button (accent semibold 16).
- **My Rating (optional)**: card with five 52-pt star targets (28 pt stars). Tap the **left half** of a star for x.5, **right half** for a whole star. Below: text `4.5 of 5` (or **"Not rated"**, muted) on the left; on the right **−** and **+** buttons (change by 0.5, − disabled when unrated, + disabled at 5) and a **Clear** button (disabled when unrated). At 0.5, − clears the rating.
- **Ingredients (optional)**: card of single-line text fields (52 pt rows, 16 pt). Each row has a trailing red `minus.circle` remove button. Footer row **Add Ingredient** (`plus.circle`, accent semibold 16). Section header **Reorder / Done** (disabled with fewer than 2 items).
- **Method (optional)**: card of rows, each a 28 pt accent number badge (serif bold 17) plus a 3-line multi-line text field. Footer row **Add Step**. Section header **Reorder / Done** (disabled with fewer than 2 items). Numbers always reflect current order.
- **Review Notes (optional)**: multi-line field (4 lines, card bg, radius 14), placeholder "How did it turn out?".
- **Delete Recipe**: full-width outlined button (danger text and dangerLine border, 50 pt, radius 14), shown only in Edit mode.

#### Reordering (editor only)
Tapping **Reorder** on Details, Ingredients, or Method puts that section into reorder mode and the button becomes **Done**. In reorder mode, rows show a trailing 3-line grip handle (44 pt target, muted) and the row's other controls are hidden (Details shows its value as plain text; Ingredients hides the remove buttons). The user **drags a row by the handle** to a new position; the row being dragged is tinted `fill`. Release drops it. Only that section changes. No reordering exists anywhere outside the editor. (In SwiftUI, `List` with `.onMove` and `editMode` for the section, or an equivalent drag-reorder.)

## Behavior summary
- Latest/Name sort is a view-only toggle, default Latest.
- Search filters by title.
- Editor: all fields except title may be empty; empty sections are simply omitted on the detail screen.
- Rating accepts 0.5 increments only.
- Detail screen is read-only; Edit button goes to the editor.

## Open items the design does not specify (decide or ask; do not invent extras)
1. **Empty list state** (no recipes yet) — not designed. Suggest the system `ContentUnavailableView`, nothing custom.
2. **Delete Recipe confirmation** — design shows only the button. HIG expects a destructive confirmation; use the standard `confirmationDialog`.
3. **Detail tile order** — design shows the default order only. This spec applies the saved Details order to the tiles so the Reorder feature has an effect.
4. The mockup's sample recipes (Roast Turkey & Apple Sandwich, Lemon Ricotta Pancakes, Rhubarb Galette, Herb Garden Focaccia, Honey Oat Scones, Radish & Chive Butter) are for previews only; do not ship them as seed data.
